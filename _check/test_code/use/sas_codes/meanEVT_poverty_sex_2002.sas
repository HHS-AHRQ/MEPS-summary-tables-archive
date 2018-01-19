ods graphics off;

/* Read in dataset and initialize year */
FILENAME h70 "C:\MEPS\h70.ssp";
proc xcopy in = h70 out = WORK IMPORT;
run;

data MEPS;
 SET h70;
 ARRAY OLDVAR(5) VARPSU02 VARSTR02 WTDPER02 AGE2X AGE1X;
 year = 2002;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU02;
  VARSTR = VARSTR02;
 end;

 if year <= 1998 then do;
  PERWT02F = WTDPER02;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE02X >= 0 then AGELAST = AGE02x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Sex */
proc format;
 value sex
 1 = "Male"
 2 = "Female";
run;

/* Poverty status */
data MEPS; set MEPS;
 ARRAY OLDPOV(1) POVCAT;
 if year = 1996 then POVCAT96 = POVCAT;
 poverty = POVCAT02;
run;

proc format;
 value poverty
 1 = "Negative or poor"
 2 = "Near-poor"
 3 = "Low income"
 4 = "Middle income"
 5 = "High income";
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
  year = 2002;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH02X &evnt.FCH02X SEEDOC ;
   SF02X = &evnt.DSF02X + &evnt.FSF02X;
   MR02X = &evnt.DMR02X + &evnt.FMR02X;
   MD02X = &evnt.DMD02X + &evnt.FMD02X;
   PV02X = &evnt.DPV02X + &evnt.FPV02X;
   VA02X = &evnt.DVA02X + &evnt.FVA02X;
   OF02X = &evnt.DOF02X + &evnt.FOF02X;
   SL02X = &evnt.DSL02X + &evnt.FSL02X;
   WC02X = &evnt.DWC02X + &evnt.FWC02X;
   OR02X = &evnt.DOR02X + &evnt.FOR02X;
   OU02X = &evnt.DOU02X + &evnt.FOU02X;
   OT02X = &evnt.DOT02X + &evnt.FOT02X;
   XP02X = &evnt.DXP02X + &evnt.FXP02X;

   if year <= 1999 then TR02X = &evnt.DCH02X + &evnt.FCH02X;
   else TR02X = &evnt.DTR02X + &evnt.FTR02X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH02X SEEDOC ;
   SF02X = &evnt.SF02X;
   MR02X = &evnt.MR02X;
   MD02X = &evnt.MD02X;
   PV02X = &evnt.PV02X;
   VA02X = &evnt.VA02X;
   OF02X = &evnt.OF02X;
   SL02X = &evnt.SL02X;
   WC02X = &evnt.WC02X;
   OR02X = &evnt.OR02X;
   OU02X = &evnt.OU02X;
   OT02X = &evnt.OT02X;
   XP02X = &evnt.XP02X;

   if year <= 1999 then TR02X = &evnt.CH02X;
   else TR02X = &evnt.TR02X;
  %end;

  PR02X = PV02X + TR02X;
  OZ02X = OF02X + SL02X + OT02X + OR02X + OU02X + WC02X + VA02X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP02X SF02X PR02X MR02X MD02X OZ02X;
 run;
%mend;

%load_events(RX,h67a);
%load_events(DV,h67b);
%load_events(IP,h67d);
%load_events(ER,h67e);
%load_events(OP,h67f);
%load_events(OB,h67g);
%load_events(HH,h67h);

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
 keep poverty sex DUPERSID PERWT02F VARSTR VARPSU;
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
 if XP02X < 0 then XP02X = .;
run;

ods output Domain = out;
proc surveymeans data = EVENTS_ge0 mean missing nobs;
 FORMAT poverty poverty. sex sex.;
 VAR XP02X;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT02F;
 DOMAIN poverty*sex;
run;

proc print data = out;
run;
