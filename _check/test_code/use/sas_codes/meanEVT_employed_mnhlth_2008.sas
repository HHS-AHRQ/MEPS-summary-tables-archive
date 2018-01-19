ods graphics off;

/* Read in dataset and initialize year */
FILENAME h121 "C:\MEPS\h121.ssp";
proc xcopy in = h121 out = WORK IMPORT;
run;

data MEPS;
 SET h121;
 ARRAY OLDVAR(5) VARPSU08 VARSTR08 WTDPER08 AGE2X AGE1X;
 year = 2008;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU08;
  VARSTR = VARSTR08;
 end;

 if year <= 1998 then do;
  PERWT08F = WTDPER08;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE08X >= 0 then AGELAST = AGE08x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Perceived mental health */
data MEPS; set MEPS;
 ARRAY OLDMNH(2) MNTHLTH1 MNTHLTH2;
 if year = 1996 then do;
  MNHLTH53 = MNTHLTH2;
  MNHLTH42 = MNTHLTH2;
  MNHLTH31 = MNTHLTH1;
 end;

 if MNHLTH53 ge 0 then mnhlth = MNHLTH53;
 else if MNHLTH42 ge 0 then mnhlth = MNHLTH42;
 else if MNHLTH31 ge 0 then mnhlth = MNHLTH31;
 else mnhlth = .;
run;

proc format;
 value mnhlth
 1 = "Excellent"
 2 = "Very good"
 3 = "Good"
 4 = "Fair"
 5 = "Poor"
 . = "Missing";
run;

/* Employment Status */
data MEPS; set MEPS;
 ARRAY OLDEMP(3) EMPST1 EMPST2 EMPST96;
 if year = 1996 then do;
  EMPST53 = EMPST96;
  EMPST42 = EMPST2;
  EMPST31 = EMPST1;
 end;

 if EMPST53 >= 0 then employ_last = EMPST53;
 else if EMPST42 >= 0 then employ_last = EMPST42;
 else if EMPST31 >= 0 then employ_last = EMPST31;
 else employ_last = .;

 employed = 1*(employ_last = 1) + 2*(employ_last > 1);
 if employed < 1 and AGELAST < 16 then employed = 9;
run;

proc format;
 value employed
 1 = "Employed"
 2 = "Not employed"
 9 = "Inapplicable (age < 16)"
 . = "Missing"
 0 = "Missing";
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
  year = 2008;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH08X &evnt.FCH08X SEEDOC ;
   SF08X = &evnt.DSF08X + &evnt.FSF08X;
   MR08X = &evnt.DMR08X + &evnt.FMR08X;
   MD08X = &evnt.DMD08X + &evnt.FMD08X;
   PV08X = &evnt.DPV08X + &evnt.FPV08X;
   VA08X = &evnt.DVA08X + &evnt.FVA08X;
   OF08X = &evnt.DOF08X + &evnt.FOF08X;
   SL08X = &evnt.DSL08X + &evnt.FSL08X;
   WC08X = &evnt.DWC08X + &evnt.FWC08X;
   OR08X = &evnt.DOR08X + &evnt.FOR08X;
   OU08X = &evnt.DOU08X + &evnt.FOU08X;
   OT08X = &evnt.DOT08X + &evnt.FOT08X;
   XP08X = &evnt.DXP08X + &evnt.FXP08X;

   if year <= 1999 then TR08X = &evnt.DCH08X + &evnt.FCH08X;
   else TR08X = &evnt.DTR08X + &evnt.FTR08X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH08X SEEDOC ;
   SF08X = &evnt.SF08X;
   MR08X = &evnt.MR08X;
   MD08X = &evnt.MD08X;
   PV08X = &evnt.PV08X;
   VA08X = &evnt.VA08X;
   OF08X = &evnt.OF08X;
   SL08X = &evnt.SL08X;
   WC08X = &evnt.WC08X;
   OR08X = &evnt.OR08X;
   OU08X = &evnt.OU08X;
   OT08X = &evnt.OT08X;
   XP08X = &evnt.XP08X;

   if year <= 1999 then TR08X = &evnt.CH08X;
   else TR08X = &evnt.TR08X;
  %end;

  PR08X = PV08X + TR08X;
  OZ08X = OF08X + SL08X + OT08X + OR08X + OU08X + WC08X + VA08X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP08X SF08X PR08X MR08X MD08X OZ08X;
 run;
%mend;

%load_events(RX,h118a);
%load_events(DV,h118b);
%load_events(IP,h118d);
%load_events(ER,h118e);
%load_events(OP,h118f);
%load_events(OB,h118g);
%load_events(HH,h118h);

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
 keep employed mnhlth DUPERSID PERWT08F VARSTR VARPSU;
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
 if XP08X < 0 then XP08X = .;
run;

ods output Domain = out;
proc surveymeans data = EVENTS_ge0 mean missing nobs;
 FORMAT employed employed. mnhlth mnhlth.;
 VAR XP08X;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT08F;
 DOMAIN employed*mnhlth;
run;

proc print data = out;
run;
