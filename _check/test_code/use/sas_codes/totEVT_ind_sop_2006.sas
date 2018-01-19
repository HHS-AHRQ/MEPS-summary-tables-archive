ods graphics off;

/* Read in dataset and initialize year */
FILENAME h105 "C:\MEPS\h105.ssp";
proc xcopy in = h105 out = WORK IMPORT;
run;

data MEPS;
 SET h105;
 ARRAY OLDVAR(5) VARPSU06 VARSTR06 WTDPER06 AGE2X AGE1X;
 year = 2006;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU06;
  VARSTR = VARSTR06;
 end;

 if year <= 1998 then do;
  PERWT06F = WTDPER06;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE06X >= 0 then AGELAST = AGE06x;
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
  year = 2006;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH06X &evnt.FCH06X SEEDOC ;
   SF06X = &evnt.DSF06X + &evnt.FSF06X;
   MR06X = &evnt.DMR06X + &evnt.FMR06X;
   MD06X = &evnt.DMD06X + &evnt.FMD06X;
   PV06X = &evnt.DPV06X + &evnt.FPV06X;
   VA06X = &evnt.DVA06X + &evnt.FVA06X;
   OF06X = &evnt.DOF06X + &evnt.FOF06X;
   SL06X = &evnt.DSL06X + &evnt.FSL06X;
   WC06X = &evnt.DWC06X + &evnt.FWC06X;
   OR06X = &evnt.DOR06X + &evnt.FOR06X;
   OU06X = &evnt.DOU06X + &evnt.FOU06X;
   OT06X = &evnt.DOT06X + &evnt.FOT06X;
   XP06X = &evnt.DXP06X + &evnt.FXP06X;

   if year <= 1999 then TR06X = &evnt.DCH06X + &evnt.FCH06X;
   else TR06X = &evnt.DTR06X + &evnt.FTR06X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH06X SEEDOC ;
   SF06X = &evnt.SF06X;
   MR06X = &evnt.MR06X;
   MD06X = &evnt.MD06X;
   PV06X = &evnt.PV06X;
   VA06X = &evnt.VA06X;
   OF06X = &evnt.OF06X;
   SL06X = &evnt.SL06X;
   WC06X = &evnt.WC06X;
   OR06X = &evnt.OR06X;
   OU06X = &evnt.OU06X;
   OT06X = &evnt.OT06X;
   XP06X = &evnt.XP06X;

   if year <= 1999 then TR06X = &evnt.CH06X;
   else TR06X = &evnt.TR06X;
  %end;

  PR06X = PV06X + TR06X;
  OZ06X = OF06X + SL06X + OT06X + OR06X + OU06X + WC06X + VA06X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP06X SF06X PR06X MR06X MD06X OZ06X;
 run;
%mend;

%load_events(RX,h102a);
%load_events(DV,h102b);
%load_events(IP,h102d);
%load_events(ER,h102e);
%load_events(OP,h102f);
%load_events(OB,h102g);
%load_events(HH,h102h);

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
 keep ind DUPERSID PERWT06F VARSTR VARPSU;
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
 array vars XP06X SF06X PR06X MR06X MD06X OZ06X;
 do over vars;
  vars = (vars > 0);
 end;
run;

ods output Domain = out;
proc surveymeans data = EVENTS_ge0 sum missing nobs;
 FORMAT ind ind.;
 VAR XP06X SF06X PR06X MR06X MD06X OZ06X;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT06F;
 DOMAIN ind;
run;

proc print data = out;
run;
