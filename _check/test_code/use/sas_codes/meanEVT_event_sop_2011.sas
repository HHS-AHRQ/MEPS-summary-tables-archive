ods graphics off;

/* Read in dataset and initialize year */
FILENAME h147 "C:\MEPS\h147.ssp";
proc xcopy in = h147 out = WORK IMPORT;
run;

data MEPS;
 SET h147;
 ARRAY OLDVAR(5) VARPSU11 VARSTR11 WTDPER11 AGE2X AGE1X;
 year = 2011;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU11;
  VARSTR = VARSTR11;
 end;

 if year <= 1998 then do;
  PERWT11F = WTDPER11;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE11X >= 0 then AGELAST = AGE11x;
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
  year = 2011;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH11X &evnt.FCH11X SEEDOC ;
   SF11X = &evnt.DSF11X + &evnt.FSF11X;
   MR11X = &evnt.DMR11X + &evnt.FMR11X;
   MD11X = &evnt.DMD11X + &evnt.FMD11X;
   PV11X = &evnt.DPV11X + &evnt.FPV11X;
   VA11X = &evnt.DVA11X + &evnt.FVA11X;
   OF11X = &evnt.DOF11X + &evnt.FOF11X;
   SL11X = &evnt.DSL11X + &evnt.FSL11X;
   WC11X = &evnt.DWC11X + &evnt.FWC11X;
   OR11X = &evnt.DOR11X + &evnt.FOR11X;
   OU11X = &evnt.DOU11X + &evnt.FOU11X;
   OT11X = &evnt.DOT11X + &evnt.FOT11X;
   XP11X = &evnt.DXP11X + &evnt.FXP11X;

   if year <= 1999 then TR11X = &evnt.DCH11X + &evnt.FCH11X;
   else TR11X = &evnt.DTR11X + &evnt.FTR11X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH11X SEEDOC ;
   SF11X = &evnt.SF11X;
   MR11X = &evnt.MR11X;
   MD11X = &evnt.MD11X;
   PV11X = &evnt.PV11X;
   VA11X = &evnt.VA11X;
   OF11X = &evnt.OF11X;
   SL11X = &evnt.SL11X;
   WC11X = &evnt.WC11X;
   OR11X = &evnt.OR11X;
   OU11X = &evnt.OU11X;
   OT11X = &evnt.OT11X;
   XP11X = &evnt.XP11X;

   if year <= 1999 then TR11X = &evnt.CH11X;
   else TR11X = &evnt.TR11X;
  %end;

  PR11X = PV11X + TR11X;
  OZ11X = OF11X + SL11X + OT11X + OR11X + OU11X + WC11X + VA11X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP11X SF11X PR11X MR11X MD11X OZ11X;
 run;
%mend;

%load_events(RX,h144a);
%load_events(DV,h144b);
%load_events(IP,h144d);
%load_events(ER,h144e);
%load_events(OP,h144f);
%load_events(OB,h144g);
%load_events(HH,h144h);

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
 keep ind DUPERSID PERWT11F VARSTR VARPSU;
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
 array vars XP11X SF11X PR11X MR11X MD11X OZ11X;
 do over vars;
  if vars < 0 then vars = .;
 end;
run;

ods output Domain = out;
proc surveymeans data = EVENTS_ge0 mean missing nobs;
 FORMAT ind ind.;
 VAR XP11X SF11X PR11X MR11X MD11X OZ11X;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT11F;
 DOMAIN ind*event;
run;

proc print data = out;
run;
