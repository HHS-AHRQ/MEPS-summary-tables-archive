ods graphics off;

/* Read in dataset and initialize year */
FILENAME h181 "C:\MEPS\h181.ssp";
proc xcopy in = h181 out = WORK IMPORT;
run;

data MEPS;
 SET h181;
 ARRAY OLDVAR(5) VARPSU15 VARSTR15 WTDPER15 AGE2X AGE1X;
 year = 2015;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU15;
  VARSTR = VARSTR15;
 end;

 if year <= 1998 then do;
  PERWT15F = WTDPER15;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE15X >= 0 then AGELAST = AGE15x;
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
  year = 2015;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH15X &evnt.FCH15X SEEDOC ;
   SF15X = &evnt.DSF15X + &evnt.FSF15X;
   MR15X = &evnt.DMR15X + &evnt.FMR15X;
   MD15X = &evnt.DMD15X + &evnt.FMD15X;
   PV15X = &evnt.DPV15X + &evnt.FPV15X;
   VA15X = &evnt.DVA15X + &evnt.FVA15X;
   OF15X = &evnt.DOF15X + &evnt.FOF15X;
   SL15X = &evnt.DSL15X + &evnt.FSL15X;
   WC15X = &evnt.DWC15X + &evnt.FWC15X;
   OR15X = &evnt.DOR15X + &evnt.FOR15X;
   OU15X = &evnt.DOU15X + &evnt.FOU15X;
   OT15X = &evnt.DOT15X + &evnt.FOT15X;
   XP15X = &evnt.DXP15X + &evnt.FXP15X;

   if year <= 1999 then TR15X = &evnt.DCH15X + &evnt.FCH15X;
   else TR15X = &evnt.DTR15X + &evnt.FTR15X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH15X SEEDOC ;
   SF15X = &evnt.SF15X;
   MR15X = &evnt.MR15X;
   MD15X = &evnt.MD15X;
   PV15X = &evnt.PV15X;
   VA15X = &evnt.VA15X;
   OF15X = &evnt.OF15X;
   SL15X = &evnt.SL15X;
   WC15X = &evnt.WC15X;
   OR15X = &evnt.OR15X;
   OU15X = &evnt.OU15X;
   OT15X = &evnt.OT15X;
   XP15X = &evnt.XP15X;

   if year <= 1999 then TR15X = &evnt.CH15X;
   else TR15X = &evnt.TR15X;
  %end;

  PR15X = PV15X + TR15X;
  OZ15X = OF15X + SL15X + OT15X + OR15X + OU15X + WC15X + VA15X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP15X SF15X PR15X MR15X MD15X OZ15X;
 run;
%mend;

%load_events(RX,h178a);
%load_events(DV,h178b);
%load_events(IP,h178d);
%load_events(ER,h178e);
%load_events(OP,h178f);
%load_events(OB,h178g);
%load_events(HH,h178h);

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
 keep ind DUPERSID PERWT15F VARSTR VARPSU;
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
 array vars XP15X SF15X PR15X MR15X MD15X OZ15X;
 do over vars;
  if vars < 0 then vars = .;
 end;
run;

ods output Domain = out;
proc surveymeans data = EVENTS_ge0 mean missing nobs;
 FORMAT ind ind.;
 VAR XP15X SF15X PR15X MR15X MD15X OZ15X;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT15F;
 DOMAIN ind*event;
run;

proc print data = out;
run;
