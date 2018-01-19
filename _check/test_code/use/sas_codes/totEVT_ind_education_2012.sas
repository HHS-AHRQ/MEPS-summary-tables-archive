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

/* Education */
data MEPS; set MEPS;
 ARRAY EDUVARS(4) EDUCYR12 EDUCYR EDUCYEAR EDRECODE;
 if year <= 1998 then EDUCYR = EDUCYR12;
 else if year <= 2004 then EDUCYR = EDUCYEAR;

 if year >= 2012 then do;
  less_than_hs = (0 <= EDRECODE and EDRECODE < 13);
  high_school  = (EDRECODE = 13);
  some_college = (EDRECODE > 13);
 end;

 else do;
  less_than_hs = (0 <= EDUCYR and EDUCYR < 12);
  high_school  = (EDUCYR = 12);
  some_college = (EDUCYR > 12);
 end;

 education = 1*less_than_hs + 2*high_school + 3*some_college;

 if AGELAST < 18 then education = 9;
run;

proc format;
 value education
 1 = "Less than high school"
 2 = "High school"
 3 = "Some college"
 9 = "Inapplicable (age < 18)"
 0 = "Missing"
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
 keep ind education DUPERSID PERWT12F VARSTR VARPSU;
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
 XP12X = (XP12X >= 0);
run;

ods output Domain = out;
proc surveymeans data = EVENTS_ge0 sum missing nobs;
 FORMAT ind ind. education education.;
 VAR XP12X;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT12F;
 DOMAIN ind*education;
run;

proc print data = out;
run;
