ods graphics off;

/* Read in dataset and initialize year */
FILENAME h12 "C:\MEPS\h12.ssp";
proc xcopy in = h12 out = WORK IMPORT;
run;

data MEPS;
 SET h12;
 ARRAY OLDVAR(5) VARPSU96 VARSTR96 WTDPER96 AGE2X AGE1X;
 year = 1996;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU96;
  VARSTR = VARSTR96;
 end;

 if year <= 1998 then do;
  PERWT96F = WTDPER96;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE96X >= 0 then AGELAST = AGE96x;
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

/* Load event files */
%macro load_events(evnt,file) / minoperator;

 FILENAME &file. "C:\MEPS\&file..ssp";
 proc xcopy in = &file. out = WORK IMPORT;
 run;

 data &evnt;
  SET &syslast; /* Most recent dataset loaded */
  ARRAY OLDVARS(2) LINKIDX EVNTIDX;
  event = "&evnt.";
  year = 1996;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH96X &evnt.FCH96X SEEDOC ;
   SF96X = &evnt.DSF96X + &evnt.FSF96X;
   MR96X = &evnt.DMR96X + &evnt.FMR96X;
   MD96X = &evnt.DMD96X + &evnt.FMD96X;
   PV96X = &evnt.DPV96X + &evnt.FPV96X;
   VA96X = &evnt.DVA96X + &evnt.FVA96X;
   OF96X = &evnt.DOF96X + &evnt.FOF96X;
   SL96X = &evnt.DSL96X + &evnt.FSL96X;
   WC96X = &evnt.DWC96X + &evnt.FWC96X;
   OR96X = &evnt.DOR96X + &evnt.FOR96X;
   OU96X = &evnt.DOU96X + &evnt.FOU96X;
   OT96X = &evnt.DOT96X + &evnt.FOT96X;
   XP96X = &evnt.DXP96X + &evnt.FXP96X;

   if year <= 1999 then TR96X = &evnt.DCH96X + &evnt.FCH96X;
   else TR96X = &evnt.DTR96X + &evnt.FTR96X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH96X SEEDOC ;
   SF96X = &evnt.SF96X;
   MR96X = &evnt.MR96X;
   MD96X = &evnt.MD96X;
   PV96X = &evnt.PV96X;
   VA96X = &evnt.VA96X;
   OF96X = &evnt.OF96X;
   SL96X = &evnt.SL96X;
   WC96X = &evnt.WC96X;
   OR96X = &evnt.OR96X;
   OU96X = &evnt.OU96X;
   OT96X = &evnt.OT96X;
   XP96X = &evnt.XP96X;

   if year <= 1999 then TR96X = &evnt.CH96X;
   else TR96X = &evnt.TR96X;
  %end;

  PR96X = PV96X + TR96X;
  OZ96X = OF96X + SL96X + OT96X + OR96X + OU96X + WC96X + VA96X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP96X SF96X PR96X MR96X MD96X OZ96X;
 run;
%mend;

%load_events(RX,hc10a);
%load_events(DV,hc10bf1);
%load_events(IP,hc10df1);
%load_events(ER,hc10ef1);
%load_events(OP,hc10ff1);
%load_events(OB,hc10gf1);
%load_events(HH,hc10hf1);

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
 keep ind sex DUPERSID PERWT96F VARSTR VARPSU;
run;

data stacked_events;
 set RX DV IP ER OP OB HH;
run;

proc sort data = stacked_events; by DUPERSID; run;
proc sort data = FYCsub; by DUPERSID; run;

data pers_events;
 merge stacked_events FYCsub;
 by DUPERSID;
 EXP = (XP96X >= 0);
run;

proc means data = pers_events sum noprint;
 by DUPERSID VARSTR VARPSU PERWT96F ind sex ;
 var EXP;
 output out = n_events sum = EXP;
run;

ods output Domain = out;
proc surveymeans data = n_events mean missing nobs;
 FORMAT ind ind. sex sex.;
 VAR EXP;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT96F;
 DOMAIN ind*sex;
run;

proc print data = out;
run;
