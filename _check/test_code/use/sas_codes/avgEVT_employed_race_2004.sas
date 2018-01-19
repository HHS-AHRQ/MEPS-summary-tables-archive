ods graphics off;

/* Read in dataset and initialize year */
FILENAME h89 "C:\MEPS\h89.ssp";
proc xcopy in = h89 out = WORK IMPORT;
run;

data MEPS;
 SET h89;
 ARRAY OLDVAR(5) VARPSU04 VARSTR04 WTDPER04 AGE2X AGE1X;
 year = 2004;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU04;
  VARSTR = VARSTR04;
 end;

 if year <= 1998 then do;
  PERWT04F = WTDPER04;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE04X >= 0 then AGELAST = AGE04x;
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
  year = 2004;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH04X &evnt.FCH04X SEEDOC ;
   SF04X = &evnt.DSF04X + &evnt.FSF04X;
   MR04X = &evnt.DMR04X + &evnt.FMR04X;
   MD04X = &evnt.DMD04X + &evnt.FMD04X;
   PV04X = &evnt.DPV04X + &evnt.FPV04X;
   VA04X = &evnt.DVA04X + &evnt.FVA04X;
   OF04X = &evnt.DOF04X + &evnt.FOF04X;
   SL04X = &evnt.DSL04X + &evnt.FSL04X;
   WC04X = &evnt.DWC04X + &evnt.FWC04X;
   OR04X = &evnt.DOR04X + &evnt.FOR04X;
   OU04X = &evnt.DOU04X + &evnt.FOU04X;
   OT04X = &evnt.DOT04X + &evnt.FOT04X;
   XP04X = &evnt.DXP04X + &evnt.FXP04X;

   if year <= 1999 then TR04X = &evnt.DCH04X + &evnt.FCH04X;
   else TR04X = &evnt.DTR04X + &evnt.FTR04X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH04X SEEDOC ;
   SF04X = &evnt.SF04X;
   MR04X = &evnt.MR04X;
   MD04X = &evnt.MD04X;
   PV04X = &evnt.PV04X;
   VA04X = &evnt.VA04X;
   OF04X = &evnt.OF04X;
   SL04X = &evnt.SL04X;
   WC04X = &evnt.WC04X;
   OR04X = &evnt.OR04X;
   OU04X = &evnt.OU04X;
   OT04X = &evnt.OT04X;
   XP04X = &evnt.XP04X;

   if year <= 1999 then TR04X = &evnt.CH04X;
   else TR04X = &evnt.TR04X;
  %end;

  PR04X = PV04X + TR04X;
  OZ04X = OF04X + SL04X + OT04X + OR04X + OU04X + WC04X + VA04X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP04X SF04X PR04X MR04X MD04X OZ04X;
 run;
%mend;

%load_events(RX,h85a);
%load_events(DV,h85b);
%load_events(IP,h85d);
%load_events(ER,h85e);
%load_events(OP,h85f);
%load_events(OB,h85g);
%load_events(HH,h85h);

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
 keep employed race DUPERSID PERWT04F VARSTR VARPSU;
run;

data stacked_events;
 set RX DV IP ER OP OB HH;
run;

proc sort data = stacked_events; by DUPERSID; run;
proc sort data = FYCsub; by DUPERSID; run;

data pers_events;
 merge stacked_events FYCsub;
 by DUPERSID;
 EXP = (XP04X >= 0);
run;

proc means data = pers_events sum noprint;
 by DUPERSID VARSTR VARPSU PERWT04F employed race ;
 var EXP;
 output out = n_events sum = EXP;
run;

ods output Domain = out;
proc surveymeans data = n_events mean missing nobs;
 FORMAT employed employed. race race.;
 VAR EXP;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT04F;
 DOMAIN employed*race;
run;

proc print data = out;
run;
