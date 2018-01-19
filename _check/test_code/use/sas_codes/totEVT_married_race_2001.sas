ods graphics off;

/* Read in dataset and initialize year */
FILENAME h60 "C:\MEPS\h60.ssp";
proc xcopy in = h60 out = WORK IMPORT;
run;

data MEPS;
 SET h60;
 ARRAY OLDVAR(5) VARPSU01 VARSTR01 WTDPER01 AGE2X AGE1X;
 year = 2001;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU01;
  VARSTR = VARSTR01;
 end;

 if year <= 1998 then do;
  PERWT01F = WTDPER01;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE01X >= 0 then AGELAST = AGE01x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Race/ethnicity */
data MEPS; set MEPS;
 ARRAY RCEVAR(4) RACETHX RACEV1X RACETHNX RACEX;
 if year >= 2012 then do;
  hisp   = (RACETHX = 1);
   white  = (RACETHX = 2);
       black  = (RACETHX = 3);
       native = (RACETHX > 3 and RACEV1X in (3,6));
       asian  = (RACETHX > 3 and RACEV1X in (4,5));
  white_oth = 0;
 end;

 else if year >= 2002 then do;
  hisp   = (RACETHNX = 1);
  white  = (RACETHNX = 4 and RACEX = 1);
  black  = (RACETHNX = 2);
  native = (RACETHNX >= 3 and RACEX in (3,6));
  asian  = (RACETHNX >= 3 and RACEX in (4,5));
  white_oth = 0;
 end;

 else do;
  hisp  = (RACETHNX = 1);
  black = (RACETHNX = 2);
  white_oth = (RACETHNX = 3);
  white  = 0;
  native = 0;
  asian  = 0;
 end;

 race = 1*hisp + 2*white + 3*black + 4*native + 5*asian + 9*white_oth;
run;

proc format;
 value race
 1 = "Hispanic"
 2 = "White"
 3 = "Black"
 4 = "Amer. Indian, AK Native, or mult. races"
 5 = "Asian, Hawaiian, or Pacific Islander"
 9 = "White and other"
 . = "Missing";
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

 if MARRY01X >= 0 then married = MARRY01X;
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
  year = 2001;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH01X &evnt.FCH01X SEEDOC ;
   SF01X = &evnt.DSF01X + &evnt.FSF01X;
   MR01X = &evnt.DMR01X + &evnt.FMR01X;
   MD01X = &evnt.DMD01X + &evnt.FMD01X;
   PV01X = &evnt.DPV01X + &evnt.FPV01X;
   VA01X = &evnt.DVA01X + &evnt.FVA01X;
   OF01X = &evnt.DOF01X + &evnt.FOF01X;
   SL01X = &evnt.DSL01X + &evnt.FSL01X;
   WC01X = &evnt.DWC01X + &evnt.FWC01X;
   OR01X = &evnt.DOR01X + &evnt.FOR01X;
   OU01X = &evnt.DOU01X + &evnt.FOU01X;
   OT01X = &evnt.DOT01X + &evnt.FOT01X;
   XP01X = &evnt.DXP01X + &evnt.FXP01X;

   if year <= 1999 then TR01X = &evnt.DCH01X + &evnt.FCH01X;
   else TR01X = &evnt.DTR01X + &evnt.FTR01X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH01X SEEDOC ;
   SF01X = &evnt.SF01X;
   MR01X = &evnt.MR01X;
   MD01X = &evnt.MD01X;
   PV01X = &evnt.PV01X;
   VA01X = &evnt.VA01X;
   OF01X = &evnt.OF01X;
   SL01X = &evnt.SL01X;
   WC01X = &evnt.WC01X;
   OR01X = &evnt.OR01X;
   OU01X = &evnt.OU01X;
   OT01X = &evnt.OT01X;
   XP01X = &evnt.XP01X;

   if year <= 1999 then TR01X = &evnt.CH01X;
   else TR01X = &evnt.TR01X;
  %end;

  PR01X = PV01X + TR01X;
  OZ01X = OF01X + SL01X + OT01X + OR01X + OU01X + WC01X + VA01X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP01X SF01X PR01X MR01X MD01X OZ01X;
 run;
%mend;

%load_events(RX,h59a);
%load_events(DV,h59b);
%load_events(IP,h59d);
%load_events(ER,h59e);
%load_events(OP,h59f);
%load_events(OB,h59g);
%load_events(HH,h59h);

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
 keep married race DUPERSID PERWT01F VARSTR VARPSU;
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
 XP01X = (XP01X >= 0);
run;

ods output Domain = out;
proc surveymeans data = EVENTS_ge0 sum missing nobs;
 FORMAT married married. race race.;
 VAR XP01X;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT01F;
 DOMAIN married*race;
run;

proc print data = out;
run;
