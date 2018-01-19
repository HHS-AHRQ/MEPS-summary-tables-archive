ods graphics off;

/* Read in dataset and initialize year */
FILENAME h38 "C:\MEPS\h38.ssp";
proc xcopy in = h38 out = WORK IMPORT;
run;

data MEPS;
 SET h38;
 ARRAY OLDVAR(5) VARPSU99 VARSTR99 WTDPER99 AGE2X AGE1X;
 year = 1999;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU99;
  VARSTR = VARSTR99;
 end;

 if year <= 1998 then do;
  PERWT99F = WTDPER99;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE99X >= 0 then AGELAST = AGE99x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Census Region */
data MEPS; set MEPS;
 ARRAY OLDREG(2) REGION1 REGION2;
 if year = 1996 then do;
  REGION42 = REGION2;
  REGION31 = REGION1;
 end;

 if REGION99 >= 0 then region = REGION99;
 else if REGION42 >= 0 then region = REGION42;
 else if REGION31 >= 0 then region = REGION31;
 else region = .;
run;

proc format;
 value region
 1 = "Northeast"
 2 = "Midwest"
 3 = "South"
 4 = "West"
 . = "Missing";
run;

/* Education */
data MEPS; set MEPS;
 ARRAY EDUVARS(4) EDUCYR99 EDUCYR EDUCYEAR EDRECODE;
 if year <= 1998 then EDUCYR = EDUCYR99;
 else if year <= 2004 then EDUCYR = EDUCYEAR;

 if year >= 2012 then do;
  less_than_hs = (0 <= EDRECODE and EDRECODE < 13);
  high_school  = (EDRECODE = 13);
  some_college = (EDRECODE > 13);
 end;

 else do;
  less_than_hs = (0 <= EDUCYR and EDUCYR < 12);
  high_school  = (EDUCYR = 12);
  some_college = (EDUCYR > 12);
 end;

 education = 1*less_than_hs + 2*high_school + 3*some_college;

 if AGELAST < 18 then education = 9;
run;

proc format;
 value education
 1 = "Less than high school"
 2 = "High school"
 3 = "Some college"
 9 = "Inapplicable (age < 18)"
 0 = "Missing"
 . = "Missing";
run;

/* Load event files */
%macro load_events(evnt,file) / minoperator;

 FILENAME &file. "C:\MEPS\&file..ssp";
 proc xcopy in = &file. out = WORK IMPORT;
 run;

 data &evnt;
  SET &syslast; /* Most recent dataset loaded */
  ARRAY OLDVARS(2) LINKIDX EVNTIDX;
  event = "&evnt.";
  year = 1999;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH99X &evnt.FCH99X SEEDOC ;
   SF99X = &evnt.DSF99X + &evnt.FSF99X;
   MR99X = &evnt.DMR99X + &evnt.FMR99X;
   MD99X = &evnt.DMD99X + &evnt.FMD99X;
   PV99X = &evnt.DPV99X + &evnt.FPV99X;
   VA99X = &evnt.DVA99X + &evnt.FVA99X;
   OF99X = &evnt.DOF99X + &evnt.FOF99X;
   SL99X = &evnt.DSL99X + &evnt.FSL99X;
   WC99X = &evnt.DWC99X + &evnt.FWC99X;
   OR99X = &evnt.DOR99X + &evnt.FOR99X;
   OU99X = &evnt.DOU99X + &evnt.FOU99X;
   OT99X = &evnt.DOT99X + &evnt.FOT99X;
   XP99X = &evnt.DXP99X + &evnt.FXP99X;

   if year <= 1999 then TR99X = &evnt.DCH99X + &evnt.FCH99X;
   else TR99X = &evnt.DTR99X + &evnt.FTR99X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH99X SEEDOC ;
   SF99X = &evnt.SF99X;
   MR99X = &evnt.MR99X;
   MD99X = &evnt.MD99X;
   PV99X = &evnt.PV99X;
   VA99X = &evnt.VA99X;
   OF99X = &evnt.OF99X;
   SL99X = &evnt.SL99X;
   WC99X = &evnt.WC99X;
   OR99X = &evnt.OR99X;
   OU99X = &evnt.OU99X;
   OT99X = &evnt.OT99X;
   XP99X = &evnt.XP99X;

   if year <= 1999 then TR99X = &evnt.CH99X;
   else TR99X = &evnt.TR99X;
  %end;

  PR99X = PV99X + TR99X;
  OZ99X = OF99X + SL99X + OT99X + OR99X + OU99X + WC99X + VA99X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP99X SF99X PR99X MR99X MD99X OZ99X;
 run;
%mend;

%load_events(RX,h33a);
%load_events(DV,h33b);
%load_events(IP,h33d);
%load_events(ER,h33e);
%load_events(OP,h33f);
%load_events(OB,h33g);
%load_events(HH,h33h);

/* Define sub-levels for office-based, outpatient, and home health */
data OB; set OB;
 if SEEDOC = 1 then event_v2X = 'OBD';
 else if SEEDOC = 2 then event_v2X = 'OBO';
 else event_v2X = '';
run;

data OP; set OP;
 if SEEDOC = 1 then event_v2X = 'OPY';
 else if SEEDOC = 2 then event_v2X = 'OPZ';
 else event_v2X = '';
run;

/* Merge with FYC file */
data FYCsub; set MEPS;
 keep education region DUPERSID PERWT99F VARSTR VARPSU;
run;

data stacked_events;
 set RX DV IP ER OP OB HH;
run;

proc sort data = stacked_events; by DUPERSID; run;
proc sort data = FYCsub; by DUPERSID; run;

data EVENTS;
 merge stacked_events FYCsub;
 by DUPERSID;
run;

data EVENTS_ge0; set EVENTS;
 XP99X = (XP99X >= 0);
run;

ods output Domain = out;
proc surveymeans data = EVENTS_ge0 sum missing nobs;
 FORMAT education education. region region.;
 VAR XP99X;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT99F;
 DOMAIN education*region;
run;

proc print data = out;
run;
