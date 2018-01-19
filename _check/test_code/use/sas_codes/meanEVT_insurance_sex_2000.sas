ods graphics off;

/* Read in dataset and initialize year */
FILENAME h50 "C:\MEPS\h50.ssp";
proc xcopy in = h50 out = WORK IMPORT;
run;

data MEPS;
 SET h50;
 ARRAY OLDVAR(5) VARPSU00 VARSTR00 WTDPER00 AGE2X AGE1X;
 year = 2000;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU00;
  VARSTR = VARSTR00;
 end;

 if year <= 1998 then do;
  PERWT00F = WTDPER00;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE00X >= 0 then AGELAST = AGE00x;
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

/* Insurance coverage */
/* To compute for insurance categories, replace 'insurance' in the SURVEY procedure with 'insurance_v2X' */
data MEPS; set MEPS;
 ARRAY OLDINS(4) MCDEVER MCREVER OPAEVER OPBEVER;
 if year = 1996 then do;
  MCDEV96 = MCDEVER;
  MCREV96 = MCREVER;
  OPAEV96 = OPAEVER;
  OPBEV96 = OPBEVER;
 end;

 if year < 2011 then do;
  public   = (MCDEV00 = 1) or (OPAEV00=1) or (OPBEV00=1);
  medicare = (MCREV00=1);
  private  = (INSCOV00=1);

  mcr_priv = (medicare and  private);
  mcr_pub  = (medicare and ~private and public);
  mcr_only = (medicare and ~private and ~public);
  no_mcr   = (~medicare);

  ins_gt65 = 4*mcr_only + 5*mcr_priv + 6*mcr_pub + 7*no_mcr;

  if AGELAST < 65 then INSURC00 = INSCOV00;
  else INSURC00 = ins_gt65;
 end;

 insurance = INSCOV00;
 insurance_v2X = INSURC00;
run;

proc format;
 value insurance
 1 = "Any private, all ages"
 2 = "Public only, all ages"
 3 = "Uninsured, all ages";

 value insurance_v2X
 1 = "<65, Any private"
 2 = "<65, Public only"
 3 = "<65, Uninsured"
 4 = "65+, Medicare only"
 5 = "65+, Medicare and private"
 6 = "65+, Medicare and other public"
 7 = "65+, No medicare"
 8 = "65+, No medicare";
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
  year = 2000;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH00X &evnt.FCH00X SEEDOC ;
   SF00X = &evnt.DSF00X + &evnt.FSF00X;
   MR00X = &evnt.DMR00X + &evnt.FMR00X;
   MD00X = &evnt.DMD00X + &evnt.FMD00X;
   PV00X = &evnt.DPV00X + &evnt.FPV00X;
   VA00X = &evnt.DVA00X + &evnt.FVA00X;
   OF00X = &evnt.DOF00X + &evnt.FOF00X;
   SL00X = &evnt.DSL00X + &evnt.FSL00X;
   WC00X = &evnt.DWC00X + &evnt.FWC00X;
   OR00X = &evnt.DOR00X + &evnt.FOR00X;
   OU00X = &evnt.DOU00X + &evnt.FOU00X;
   OT00X = &evnt.DOT00X + &evnt.FOT00X;
   XP00X = &evnt.DXP00X + &evnt.FXP00X;

   if year <= 1999 then TR00X = &evnt.DCH00X + &evnt.FCH00X;
   else TR00X = &evnt.DTR00X + &evnt.FTR00X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH00X SEEDOC ;
   SF00X = &evnt.SF00X;
   MR00X = &evnt.MR00X;
   MD00X = &evnt.MD00X;
   PV00X = &evnt.PV00X;
   VA00X = &evnt.VA00X;
   OF00X = &evnt.OF00X;
   SL00X = &evnt.SL00X;
   WC00X = &evnt.WC00X;
   OR00X = &evnt.OR00X;
   OU00X = &evnt.OU00X;
   OT00X = &evnt.OT00X;
   XP00X = &evnt.XP00X;

   if year <= 1999 then TR00X = &evnt.CH00X;
   else TR00X = &evnt.TR00X;
  %end;

  PR00X = PV00X + TR00X;
  OZ00X = OF00X + SL00X + OT00X + OR00X + OU00X + WC00X + VA00X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP00X SF00X PR00X MR00X MD00X OZ00X;
 run;
%mend;

%load_events(RX,h51a);
%load_events(DV,h51b);
%load_events(IP,h51d);
%load_events(ER,h51e);
%load_events(OP,h51f);
%load_events(OB,h51g);
%load_events(HH,h51h);

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
 keep insurance sex DUPERSID PERWT00F VARSTR VARPSU;
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
 if XP00X < 0 then XP00X = .;
run;

ods output Domain = out;
proc surveymeans data = EVENTS_ge0 mean missing nobs;
 FORMAT insurance insurance. sex sex.;
 VAR XP00X;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT00F;
 DOMAIN insurance*sex;
run;

proc print data = out;
run;
