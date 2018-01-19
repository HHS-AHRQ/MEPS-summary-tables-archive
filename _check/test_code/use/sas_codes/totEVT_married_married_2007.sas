ods graphics off;

/* Read in dataset and initialize year */
FILENAME h113 "C:\MEPS\h113.ssp";
proc xcopy in = h113 out = WORK IMPORT;
run;

data MEPS;
 SET h113;
 ARRAY OLDVAR(5) VARPSU07 VARSTR07 WTDPER07 AGE2X AGE1X;
 year = 2007;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU07;
  VARSTR = VARSTR07;
 end;

 if year <= 1998 then do;
  PERWT07F = WTDPER07;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE07X >= 0 then AGELAST = AGE07x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Marital Status */
data MEPS; set MEPS;
 ARRAY OLDMAR(2) MARRY1X MARRY2X;
 if year = 1996 then do;
  if MARRY2X <= 6 then MARRY42X = MARRY2X;
  else MARRY42X = MARRY2X-6;

  if MARRY1X <= 6 then MARRY31X = MARRY1X;
  else MARRY31X = MARRY1X-6;
 end;

 if MARRY07X >= 0 then married = MARRY07X;
 else if MARRY42X >= 0 then married = MARRY42X;
 else if MARRY31X >= 0 then married = MARRY31X;
 else married = .;
run;

proc format;
 value married
 1 = "Married"
 2 = "Widowed"
 3 = "Divorced"
 4 = "Separated"
 5 = "Never married"
 6 = "Inapplicable (age < 16)"
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
  year = 2007;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH07X &evnt.FCH07X SEEDOC ;
   SF07X = &evnt.DSF07X + &evnt.FSF07X;
   MR07X = &evnt.DMR07X + &evnt.FMR07X;
   MD07X = &evnt.DMD07X + &evnt.FMD07X;
   PV07X = &evnt.DPV07X + &evnt.FPV07X;
   VA07X = &evnt.DVA07X + &evnt.FVA07X;
   OF07X = &evnt.DOF07X + &evnt.FOF07X;
   SL07X = &evnt.DSL07X + &evnt.FSL07X;
   WC07X = &evnt.DWC07X + &evnt.FWC07X;
   OR07X = &evnt.DOR07X + &evnt.FOR07X;
   OU07X = &evnt.DOU07X + &evnt.FOU07X;
   OT07X = &evnt.DOT07X + &evnt.FOT07X;
   XP07X = &evnt.DXP07X + &evnt.FXP07X;

   if year <= 1999 then TR07X = &evnt.DCH07X + &evnt.FCH07X;
   else TR07X = &evnt.DTR07X + &evnt.FTR07X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH07X SEEDOC ;
   SF07X = &evnt.SF07X;
   MR07X = &evnt.MR07X;
   MD07X = &evnt.MD07X;
   PV07X = &evnt.PV07X;
   VA07X = &evnt.VA07X;
   OF07X = &evnt.OF07X;
   SL07X = &evnt.SL07X;
   WC07X = &evnt.WC07X;
   OR07X = &evnt.OR07X;
   OU07X = &evnt.OU07X;
   OT07X = &evnt.OT07X;
   XP07X = &evnt.XP07X;

   if year <= 1999 then TR07X = &evnt.CH07X;
   else TR07X = &evnt.TR07X;
  %end;

  PR07X = PV07X + TR07X;
  OZ07X = OF07X + SL07X + OT07X + OR07X + OU07X + WC07X + VA07X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP07X SF07X PR07X MR07X MD07X OZ07X;
 run;
%mend;

%load_events(RX,h110a);
%load_events(DV,h110b);
%load_events(IP,h110d);
%load_events(ER,h110e);
%load_events(OP,h110f);
%load_events(OB,h110g);
%load_events(HH,h110h);

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
 keep ind married DUPERSID PERWT07F VARSTR VARPSU;
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
 XP07X = (XP07X >= 0);
run;

ods output Domain = out;
proc surveymeans data = EVENTS_ge0 sum missing nobs;
 FORMAT ind ind. married married.;
 VAR XP07X;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT07F;
 DOMAIN ind*married;
run;

proc print data = out;
run;
