ods graphics off;

/* Read in dataset and initialize year */
FILENAME h129 "C:\MEPS\h129.ssp";
proc xcopy in = h129 out = WORK IMPORT;
run;

data MEPS;
 SET h129;
 ARRAY OLDVAR(5) VARPSU09 VARSTR09 WTDPER09 AGE2X AGE1X;
 year = 2009;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU09;
  VARSTR = VARSTR09;
 end;

 if year <= 1998 then do;
  PERWT09F = WTDPER09;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE09X >= 0 then AGELAST = AGE09x;
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

/* Age groups */
/* To compute for all age groups, replace 'agegrps' in the SURVEY procedure with 'agegrps_v2X'  */
data MEPS; set MEPS;
 agegrps = AGELAST;
 agegrps_v2X = AGELAST;
 agegrps_v3X = AGELAST;
run;

proc format;
 value agegrps
 low-4 = "Under 5"
 5-17  = "5-17"
 18-44 = "18-44"
 45-64 = "45-64"
 65-high = "65+";

 value agegrps_v2X
 low-17  = "Under 18"
 18-64   = "18-64"
 65-high = "65+";

 value agegrps_v3X
 low-4 = "Under 5"
 5-6   = "5-6"
 7-12  = "7-12"
 13-17 = "13-17"
 18    = "18"
 19-24 = "19-24"
 25-29 = "25-29"
 30-34 = "30-34"
 35-44 = "35-44"
 45-54 = "45-54"
 55-64 = "55-64"
 65-high = "65+";
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
  year = 2009;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH09X &evnt.FCH09X SEEDOC ;
   SF09X = &evnt.DSF09X + &evnt.FSF09X;
   MR09X = &evnt.DMR09X + &evnt.FMR09X;
   MD09X = &evnt.DMD09X + &evnt.FMD09X;
   PV09X = &evnt.DPV09X + &evnt.FPV09X;
   VA09X = &evnt.DVA09X + &evnt.FVA09X;
   OF09X = &evnt.DOF09X + &evnt.FOF09X;
   SL09X = &evnt.DSL09X + &evnt.FSL09X;
   WC09X = &evnt.DWC09X + &evnt.FWC09X;
   OR09X = &evnt.DOR09X + &evnt.FOR09X;
   OU09X = &evnt.DOU09X + &evnt.FOU09X;
   OT09X = &evnt.DOT09X + &evnt.FOT09X;
   XP09X = &evnt.DXP09X + &evnt.FXP09X;

   if year <= 1999 then TR09X = &evnt.DCH09X + &evnt.FCH09X;
   else TR09X = &evnt.DTR09X + &evnt.FTR09X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH09X SEEDOC ;
   SF09X = &evnt.SF09X;
   MR09X = &evnt.MR09X;
   MD09X = &evnt.MD09X;
   PV09X = &evnt.PV09X;
   VA09X = &evnt.VA09X;
   OF09X = &evnt.OF09X;
   SL09X = &evnt.SL09X;
   WC09X = &evnt.WC09X;
   OR09X = &evnt.OR09X;
   OU09X = &evnt.OU09X;
   OT09X = &evnt.OT09X;
   XP09X = &evnt.XP09X;

   if year <= 1999 then TR09X = &evnt.CH09X;
   else TR09X = &evnt.TR09X;
  %end;

  PR09X = PV09X + TR09X;
  OZ09X = OF09X + SL09X + OT09X + OR09X + OU09X + WC09X + VA09X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP09X SF09X PR09X MR09X MD09X OZ09X;
 run;
%mend;

%load_events(RX,h126a);
%load_events(DV,h126b);
%load_events(IP,h126d);
%load_events(ER,h126e);
%load_events(OP,h126f);
%load_events(OB,h126g);
%load_events(HH,h126h);

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
 keep agegrps sex DUPERSID PERWT09F VARSTR VARPSU;
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
 if XP09X < 0 then XP09X = .;
run;

ods output Domain = out;
proc surveymeans data = EVENTS_ge0 mean missing nobs;
 FORMAT agegrps agegrps. sex sex.;
 VAR XP09X;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT09F;
 DOMAIN agegrps*sex;
run;

proc print data = out;
run;
