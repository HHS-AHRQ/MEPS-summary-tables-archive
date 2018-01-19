ods graphics off;

/* Read in dataset and initialize year */
FILENAME h163 "C:\MEPS\h163.ssp";
proc xcopy in = h163 out = WORK IMPORT;
run;

data MEPS;
 SET h163;
 ARRAY OLDVAR(5) VARPSU13 VARSTR13 WTDPER13 AGE2X AGE1X;
 year = 2013;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU13;
  VARSTR = VARSTR13;
 end;

 if year <= 1998 then do;
  PERWT13F = WTDPER13;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE13X >= 0 then AGELAST = AGE13x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Education */
data MEPS; set MEPS;
 ARRAY EDUVARS(4) EDUCYR13 EDUCYR EDUCYEAR EDRECODE;
 if year <= 1998 then EDUCYR = EDUCYR13;
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
  year = 2013;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH13X &evnt.FCH13X SEEDOC ;
   SF13X = &evnt.DSF13X + &evnt.FSF13X;
   MR13X = &evnt.DMR13X + &evnt.FMR13X;
   MD13X = &evnt.DMD13X + &evnt.FMD13X;
   PV13X = &evnt.DPV13X + &evnt.FPV13X;
   VA13X = &evnt.DVA13X + &evnt.FVA13X;
   OF13X = &evnt.DOF13X + &evnt.FOF13X;
   SL13X = &evnt.DSL13X + &evnt.FSL13X;
   WC13X = &evnt.DWC13X + &evnt.FWC13X;
   OR13X = &evnt.DOR13X + &evnt.FOR13X;
   OU13X = &evnt.DOU13X + &evnt.FOU13X;
   OT13X = &evnt.DOT13X + &evnt.FOT13X;
   XP13X = &evnt.DXP13X + &evnt.FXP13X;

   if year <= 1999 then TR13X = &evnt.DCH13X + &evnt.FCH13X;
   else TR13X = &evnt.DTR13X + &evnt.FTR13X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH13X SEEDOC ;
   SF13X = &evnt.SF13X;
   MR13X = &evnt.MR13X;
   MD13X = &evnt.MD13X;
   PV13X = &evnt.PV13X;
   VA13X = &evnt.VA13X;
   OF13X = &evnt.OF13X;
   SL13X = &evnt.SL13X;
   WC13X = &evnt.WC13X;
   OR13X = &evnt.OR13X;
   OU13X = &evnt.OU13X;
   OT13X = &evnt.OT13X;
   XP13X = &evnt.XP13X;

   if year <= 1999 then TR13X = &evnt.CH13X;
   else TR13X = &evnt.TR13X;
  %end;

  PR13X = PV13X + TR13X;
  OZ13X = OF13X + SL13X + OT13X + OR13X + OU13X + WC13X + VA13X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP13X SF13X PR13X MR13X MD13X OZ13X;
 run;
%mend;

%load_events(RX,h160a);
%load_events(DV,h160b);
%load_events(IP,h160d);
%load_events(ER,h160e);
%load_events(OP,h160f);
%load_events(OB,h160g);
%load_events(HH,h160h);

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
 keep ind education DUPERSID PERWT13F VARSTR VARPSU;
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
 if XP13X < 0 then XP13X = .;
run;

ods output Domain = out;
proc surveymeans data = EVENTS_ge0 mean missing nobs;
 FORMAT ind ind. education education.;
 VAR XP13X;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT13F;
 DOMAIN ind*education;
run;

proc print data = out;
run;
