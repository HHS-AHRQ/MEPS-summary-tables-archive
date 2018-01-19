ods graphics off;

/* Read in dataset and initialize year */
FILENAME h155 "C:\MEPS\h155.ssp";
proc xcopy in = h155 out = WORK IMPORT;
run;

data MEPS;
 SET h155;
 ARRAY OLDVAR(5) VARPSU12 VARSTR12 WTDPER12 AGE2X AGE1X;
 year = 2012;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU12;
  VARSTR = VARSTR12;
 end;

 if year <= 1998 then do;
  PERWT12F = WTDPER12;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE12X >= 0 then AGELAST = AGE12x;
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

/* Load event files */
%macro load_events(evnt,file) / minoperator;

 FILENAME &file. "C:\MEPS\&file..ssp";
 proc xcopy in = &file. out = WORK IMPORT;
 run;

 data &evnt;
  SET &syslast; /* Most recent dataset loaded */
  ARRAY OLDVARS(2) LINKIDX EVNTIDX;
  event = "&evnt.";
  year = 2012;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH12X &evnt.FCH12X SEEDOC ;
   SF12X = &evnt.DSF12X + &evnt.FSF12X;
   MR12X = &evnt.DMR12X + &evnt.FMR12X;
   MD12X = &evnt.DMD12X + &evnt.FMD12X;
   PV12X = &evnt.DPV12X + &evnt.FPV12X;
   VA12X = &evnt.DVA12X + &evnt.FVA12X;
   OF12X = &evnt.DOF12X + &evnt.FOF12X;
   SL12X = &evnt.DSL12X + &evnt.FSL12X;
   WC12X = &evnt.DWC12X + &evnt.FWC12X;
   OR12X = &evnt.DOR12X + &evnt.FOR12X;
   OU12X = &evnt.DOU12X + &evnt.FOU12X;
   OT12X = &evnt.DOT12X + &evnt.FOT12X;
   XP12X = &evnt.DXP12X + &evnt.FXP12X;

   if year <= 1999 then TR12X = &evnt.DCH12X + &evnt.FCH12X;
   else TR12X = &evnt.DTR12X + &evnt.FTR12X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH12X SEEDOC ;
   SF12X = &evnt.SF12X;
   MR12X = &evnt.MR12X;
   MD12X = &evnt.MD12X;
   PV12X = &evnt.PV12X;
   VA12X = &evnt.VA12X;
   OF12X = &evnt.OF12X;
   SL12X = &evnt.SL12X;
   WC12X = &evnt.WC12X;
   OR12X = &evnt.OR12X;
   OU12X = &evnt.OU12X;
   OT12X = &evnt.OT12X;
   XP12X = &evnt.XP12X;

   if year <= 1999 then TR12X = &evnt.CH12X;
   else TR12X = &evnt.TR12X;
  %end;

  PR12X = PV12X + TR12X;
  OZ12X = OF12X + SL12X + OT12X + OR12X + OU12X + WC12X + VA12X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP12X SF12X PR12X MR12X MD12X OZ12X;
 run;
%mend;

%load_events(RX,h152a);
%load_events(DV,h152b);
%load_events(IP,h152d);
%load_events(ER,h152e);
%load_events(OP,h152f);
%load_events(OB,h152g);
%load_events(HH,h152h);

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
 keep ind race DUPERSID PERWT12F VARSTR VARPSU;
run;

data stacked_events;
 set RX DV IP ER OP OB HH;
run;

proc sort data = stacked_events; by DUPERSID; run;
proc sort data = FYCsub; by DUPERSID; run;

data pers_events;
 merge stacked_events FYCsub;
 by DUPERSID;
 EXP = (XP12X >= 0);
run;

proc means data = pers_events sum noprint;
 by DUPERSID VARSTR VARPSU PERWT12F ind race ;
 var EXP;
 output out = n_events sum = EXP;
run;

ods output Domain = out;
proc surveymeans data = n_events mean missing nobs;
 FORMAT ind ind. race race.;
 VAR EXP;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT12F;
 DOMAIN ind*race;
run;

proc print data = out;
run;
