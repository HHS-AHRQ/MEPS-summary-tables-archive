ods graphics off;

/* Read in dataset and initialize year */
FILENAME h79 "C:\MEPS\h79.ssp";
proc xcopy in = h79 out = WORK IMPORT;
run;

data MEPS;
 SET h79;
 ARRAY OLDVAR(5) VARPSU03 VARSTR03 WTDPER03 AGE2X AGE1X;
 year = 2003;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU03;
  VARSTR = VARSTR03;
 end;

 if year <= 1998 then do;
  PERWT03F = WTDPER03;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE03X >= 0 then AGELAST = AGE03x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Education */
data MEPS; set MEPS;
 ARRAY EDUVARS(4) EDUCYR03 EDUCYR EDUCYEAR EDRECODE;
 if year <= 1998 then EDUCYR = EDUCYR03;
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

/* Sex */
proc format;
 value sex
 1 = "Male"
 2 = "Female";
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
  year = 2003;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH03X &evnt.FCH03X SEEDOC ;
   SF03X = &evnt.DSF03X + &evnt.FSF03X;
   MR03X = &evnt.DMR03X + &evnt.FMR03X;
   MD03X = &evnt.DMD03X + &evnt.FMD03X;
   PV03X = &evnt.DPV03X + &evnt.FPV03X;
   VA03X = &evnt.DVA03X + &evnt.FVA03X;
   OF03X = &evnt.DOF03X + &evnt.FOF03X;
   SL03X = &evnt.DSL03X + &evnt.FSL03X;
   WC03X = &evnt.DWC03X + &evnt.FWC03X;
   OR03X = &evnt.DOR03X + &evnt.FOR03X;
   OU03X = &evnt.DOU03X + &evnt.FOU03X;
   OT03X = &evnt.DOT03X + &evnt.FOT03X;
   XP03X = &evnt.DXP03X + &evnt.FXP03X;

   if year <= 1999 then TR03X = &evnt.DCH03X + &evnt.FCH03X;
   else TR03X = &evnt.DTR03X + &evnt.FTR03X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH03X SEEDOC ;
   SF03X = &evnt.SF03X;
   MR03X = &evnt.MR03X;
   MD03X = &evnt.MD03X;
   PV03X = &evnt.PV03X;
   VA03X = &evnt.VA03X;
   OF03X = &evnt.OF03X;
   SL03X = &evnt.SL03X;
   WC03X = &evnt.WC03X;
   OR03X = &evnt.OR03X;
   OU03X = &evnt.OU03X;
   OT03X = &evnt.OT03X;
   XP03X = &evnt.XP03X;

   if year <= 1999 then TR03X = &evnt.CH03X;
   else TR03X = &evnt.TR03X;
  %end;

  PR03X = PV03X + TR03X;
  OZ03X = OF03X + SL03X + OT03X + OR03X + OU03X + WC03X + VA03X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP03X SF03X PR03X MR03X MD03X OZ03X;
 run;
%mend;

%load_events(RX,h77a);
%load_events(DV,h77b);
%load_events(IP,h77d);
%load_events(ER,h77e);
%load_events(OP,h77f);
%load_events(OB,h77g);
%load_events(HH,h77h);

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
 keep sex education DUPERSID PERWT03F VARSTR VARPSU;
run;

data stacked_events;
 set RX DV IP ER OP OB HH;
run;

proc sort data = stacked_events; by DUPERSID; run;
proc sort data = FYCsub; by DUPERSID; run;

data pers_events;
 merge stacked_events FYCsub;
 by DUPERSID;
 EXP = (XP03X >= 0);
run;

proc means data = pers_events sum noprint;
 by DUPERSID VARSTR VARPSU PERWT03F sex education ;
 var EXP;
 output out = n_events sum = EXP;
run;

ods output Domain = out;
proc surveymeans data = n_events mean missing nobs;
 FORMAT sex sex. education education.;
 VAR EXP;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT03F;
 DOMAIN sex*education;
run;

proc print data = out;
run;
