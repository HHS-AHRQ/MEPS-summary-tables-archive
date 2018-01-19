ods graphics off;

/* Read in dataset and initialize year */
FILENAME h138 "C:\MEPS\h138.ssp";
proc xcopy in = h138 out = WORK IMPORT;
run;

data MEPS;
 SET h138;
 ARRAY OLDVAR(5) VARPSU10 VARSTR10 WTDPER10 AGE2X AGE1X;
 year = 2010;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU10;
  VARSTR = VARSTR10;
 end;

 if year <= 1998 then do;
  PERWT10F = WTDPER10;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE10X >= 0 then AGELAST = AGE10x;
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
 poverty = POVCAT10;
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
  year = 2010;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH10X &evnt.FCH10X SEEDOC ;
   SF10X = &evnt.DSF10X + &evnt.FSF10X;
   MR10X = &evnt.DMR10X + &evnt.FMR10X;
   MD10X = &evnt.DMD10X + &evnt.FMD10X;
   PV10X = &evnt.DPV10X + &evnt.FPV10X;
   VA10X = &evnt.DVA10X + &evnt.FVA10X;
   OF10X = &evnt.DOF10X + &evnt.FOF10X;
   SL10X = &evnt.DSL10X + &evnt.FSL10X;
   WC10X = &evnt.DWC10X + &evnt.FWC10X;
   OR10X = &evnt.DOR10X + &evnt.FOR10X;
   OU10X = &evnt.DOU10X + &evnt.FOU10X;
   OT10X = &evnt.DOT10X + &evnt.FOT10X;
   XP10X = &evnt.DXP10X + &evnt.FXP10X;

   if year <= 1999 then TR10X = &evnt.DCH10X + &evnt.FCH10X;
   else TR10X = &evnt.DTR10X + &evnt.FTR10X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH10X SEEDOC ;
   SF10X = &evnt.SF10X;
   MR10X = &evnt.MR10X;
   MD10X = &evnt.MD10X;
   PV10X = &evnt.PV10X;
   VA10X = &evnt.VA10X;
   OF10X = &evnt.OF10X;
   SL10X = &evnt.SL10X;
   WC10X = &evnt.WC10X;
   OR10X = &evnt.OR10X;
   OU10X = &evnt.OU10X;
   OT10X = &evnt.OT10X;
   XP10X = &evnt.XP10X;

   if year <= 1999 then TR10X = &evnt.CH10X;
   else TR10X = &evnt.TR10X;
  %end;

  PR10X = PV10X + TR10X;
  OZ10X = OF10X + SL10X + OT10X + OR10X + OU10X + WC10X + VA10X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP10X SF10X PR10X MR10X MD10X OZ10X;
 run;
%mend;

%load_events(RX,h135a);
%load_events(DV,h135b);
%load_events(IP,h135d);
%load_events(ER,h135e);
%load_events(OP,h135f);
%load_events(OB,h135g);
%load_events(HH,h135h);

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
 keep poverty DUPERSID PERWT10F VARSTR VARPSU;
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
 XP10X = (XP10X >= 0);
run;

ods output Domain = out;
proc surveymeans data = EVENTS_ge0 sum missing nobs;
 FORMAT poverty poverty.;
 VAR XP10X;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT10F;
 DOMAIN poverty*event;
run;

proc print data = out;
run;
