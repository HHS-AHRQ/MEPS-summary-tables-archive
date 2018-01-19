ods graphics off;

/* Read in dataset and initialize year */
FILENAME h171 "C:\MEPS\h171.ssp";
proc xcopy in = h171 out = WORK IMPORT;
run;

data MEPS;
 SET h171;
 ARRAY OLDVAR(5) VARPSU14 VARSTR14 WTDPER14 AGE2X AGE1X;
 year = 2014;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU14;
  VARSTR = VARSTR14;
 end;

 if year <= 1998 then do;
  PERWT14F = WTDPER14;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE14X >= 0 then AGELAST = AGE14x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
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
  year = 2014;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH14X &evnt.FCH14X SEEDOC ;
   SF14X = &evnt.DSF14X + &evnt.FSF14X;
   MR14X = &evnt.DMR14X + &evnt.FMR14X;
   MD14X = &evnt.DMD14X + &evnt.FMD14X;
   PV14X = &evnt.DPV14X + &evnt.FPV14X;
   VA14X = &evnt.DVA14X + &evnt.FVA14X;
   OF14X = &evnt.DOF14X + &evnt.FOF14X;
   SL14X = &evnt.DSL14X + &evnt.FSL14X;
   WC14X = &evnt.DWC14X + &evnt.FWC14X;
   OR14X = &evnt.DOR14X + &evnt.FOR14X;
   OU14X = &evnt.DOU14X + &evnt.FOU14X;
   OT14X = &evnt.DOT14X + &evnt.FOT14X;
   XP14X = &evnt.DXP14X + &evnt.FXP14X;

   if year <= 1999 then TR14X = &evnt.DCH14X + &evnt.FCH14X;
   else TR14X = &evnt.DTR14X + &evnt.FTR14X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH14X SEEDOC ;
   SF14X = &evnt.SF14X;
   MR14X = &evnt.MR14X;
   MD14X = &evnt.MD14X;
   PV14X = &evnt.PV14X;
   VA14X = &evnt.VA14X;
   OF14X = &evnt.OF14X;
   SL14X = &evnt.SL14X;
   WC14X = &evnt.WC14X;
   OR14X = &evnt.OR14X;
   OU14X = &evnt.OU14X;
   OT14X = &evnt.OT14X;
   XP14X = &evnt.XP14X;

   if year <= 1999 then TR14X = &evnt.CH14X;
   else TR14X = &evnt.TR14X;
  %end;

  PR14X = PV14X + TR14X;
  OZ14X = OF14X + SL14X + OT14X + OR14X + OU14X + WC14X + VA14X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP14X SF14X PR14X MR14X MD14X OZ14X;
 run;
%mend;

%load_events(RX,h168a);
%load_events(DV,h168b);
%load_events(IP,h168d);
%load_events(ER,h168e);
%load_events(OP,h168f);
%load_events(OB,h168g);
%load_events(HH,h168h);

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
 keep ind DUPERSID PERWT14F VARSTR VARPSU;
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
 if XP14X < 0 then XP14X = .;
run;

ods output Domain = out;
proc surveymeans data = EVENTS_ge0 mean missing nobs;
 FORMAT ind ind.;
 VAR XP14X;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT14F;
 DOMAIN ind;
run;

proc print data = out;
run;
