ods graphics off;

/* Read in dataset and initialize year */
FILENAME h97 "C:\MEPS\h97.ssp";
proc xcopy in = h97 out = WORK IMPORT;
run;

data MEPS;
 SET h97;
 ARRAY OLDVAR(5) VARPSU05 VARSTR05 WTDPER05 AGE2X AGE1X;
 year = 2005;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU05;
  VARSTR = VARSTR05;
 end;

 if year <= 1998 then do;
  PERWT05F = WTDPER05;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE05X >= 0 then AGELAST = AGE05x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Poverty status */
data MEPS; set MEPS;
 ARRAY OLDPOV(1) POVCAT;
 if year = 1996 then POVCAT96 = POVCAT;
 poverty = POVCAT05;
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
  year = 2005;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH05X &evnt.FCH05X SEEDOC ;
   SF05X = &evnt.DSF05X + &evnt.FSF05X;
   MR05X = &evnt.DMR05X + &evnt.FMR05X;
   MD05X = &evnt.DMD05X + &evnt.FMD05X;
   PV05X = &evnt.DPV05X + &evnt.FPV05X;
   VA05X = &evnt.DVA05X + &evnt.FVA05X;
   OF05X = &evnt.DOF05X + &evnt.FOF05X;
   SL05X = &evnt.DSL05X + &evnt.FSL05X;
   WC05X = &evnt.DWC05X + &evnt.FWC05X;
   OR05X = &evnt.DOR05X + &evnt.FOR05X;
   OU05X = &evnt.DOU05X + &evnt.FOU05X;
   OT05X = &evnt.DOT05X + &evnt.FOT05X;
   XP05X = &evnt.DXP05X + &evnt.FXP05X;

   if year <= 1999 then TR05X = &evnt.DCH05X + &evnt.FCH05X;
   else TR05X = &evnt.DTR05X + &evnt.FTR05X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH05X SEEDOC ;
   SF05X = &evnt.SF05X;
   MR05X = &evnt.MR05X;
   MD05X = &evnt.MD05X;
   PV05X = &evnt.PV05X;
   VA05X = &evnt.VA05X;
   OF05X = &evnt.OF05X;
   SL05X = &evnt.SL05X;
   WC05X = &evnt.WC05X;
   OR05X = &evnt.OR05X;
   OU05X = &evnt.OU05X;
   OT05X = &evnt.OT05X;
   XP05X = &evnt.XP05X;

   if year <= 1999 then TR05X = &evnt.CH05X;
   else TR05X = &evnt.TR05X;
  %end;

  PR05X = PV05X + TR05X;
  OZ05X = OF05X + SL05X + OT05X + OR05X + OU05X + WC05X + VA05X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP05X SF05X PR05X MR05X MD05X OZ05X;
 run;
%mend;

%load_events(RX,h94a);
%load_events(DV,h94b);
%load_events(IP,h94d);
%load_events(ER,h94e);
%load_events(OP,h94f);
%load_events(OB,h94g);
%load_events(HH,h94h);

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
 keep ind poverty DUPERSID PERWT05F VARSTR VARPSU;
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
 XP05X = (XP05X >= 0);
run;

ods output Domain = out;
proc surveymeans data = EVENTS_ge0 sum missing nobs;
 FORMAT ind ind. poverty poverty.;
 VAR XP05X;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT05F;
 DOMAIN ind*poverty;
run;

proc print data = out;
run;
