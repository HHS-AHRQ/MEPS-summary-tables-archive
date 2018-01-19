ods graphics off;

/* Read in dataset and initialize year */
FILENAME h20 "C:\MEPS\h20.ssp";
proc xcopy in = h20 out = WORK IMPORT;
run;

data MEPS;
 SET h20;
 ARRAY OLDVAR(5) VARPSU97 VARSTR97 WTDPER97 AGE2X AGE1X;
 year = 1997;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU97;
  VARSTR = VARSTR97;
 end;

 if year <= 1998 then do;
  PERWT97F = WTDPER97;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE97X >= 0 then AGELAST = AGE97x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
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
  public   = (MCDEV97 = 1) or (OPAEV97=1) or (OPBEV97=1);
  medicare = (MCREV97=1);
  private  = (INSCOV97=1);

  mcr_priv = (medicare and  private);
  mcr_pub  = (medicare and ~private and public);
  mcr_only = (medicare and ~private and ~public);
  no_mcr   = (~medicare);

  ins_gt65 = 4*mcr_only + 5*mcr_priv + 6*mcr_pub + 7*no_mcr;

  if AGELAST < 65 then INSURC97 = INSCOV97;
  else INSURC97 = ins_gt65;
 end;

 insurance = INSCOV97;
 insurance_v2X = INSURC97;
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

/* Education */
data MEPS; set MEPS;
 ARRAY EDUVARS(4) EDUCYR97 EDUCYR EDUCYEAR EDRECODE;
 if year <= 1998 then EDUCYR = EDUCYR97;
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
  year = 1997;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH97X &evnt.FCH97X SEEDOC ;
   SF97X = &evnt.DSF97X + &evnt.FSF97X;
   MR97X = &evnt.DMR97X + &evnt.FMR97X;
   MD97X = &evnt.DMD97X + &evnt.FMD97X;
   PV97X = &evnt.DPV97X + &evnt.FPV97X;
   VA97X = &evnt.DVA97X + &evnt.FVA97X;
   OF97X = &evnt.DOF97X + &evnt.FOF97X;
   SL97X = &evnt.DSL97X + &evnt.FSL97X;
   WC97X = &evnt.DWC97X + &evnt.FWC97X;
   OR97X = &evnt.DOR97X + &evnt.FOR97X;
   OU97X = &evnt.DOU97X + &evnt.FOU97X;
   OT97X = &evnt.DOT97X + &evnt.FOT97X;
   XP97X = &evnt.DXP97X + &evnt.FXP97X;

   if year <= 1999 then TR97X = &evnt.DCH97X + &evnt.FCH97X;
   else TR97X = &evnt.DTR97X + &evnt.FTR97X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH97X SEEDOC ;
   SF97X = &evnt.SF97X;
   MR97X = &evnt.MR97X;
   MD97X = &evnt.MD97X;
   PV97X = &evnt.PV97X;
   VA97X = &evnt.VA97X;
   OF97X = &evnt.OF97X;
   SL97X = &evnt.SL97X;
   WC97X = &evnt.WC97X;
   OR97X = &evnt.OR97X;
   OU97X = &evnt.OU97X;
   OT97X = &evnt.OT97X;
   XP97X = &evnt.XP97X;

   if year <= 1999 then TR97X = &evnt.CH97X;
   else TR97X = &evnt.TR97X;
  %end;

  PR97X = PV97X + TR97X;
  OZ97X = OF97X + SL97X + OT97X + OR97X + OU97X + WC97X + VA97X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP97X SF97X PR97X MR97X MD97X OZ97X;
 run;
%mend;

%load_events(RX,h16a);
%load_events(DV,hc16bf1);
%load_events(IP,hc16df1);
%load_events(ER,hc16ef1);
%load_events(OP,hc16ff1);
%load_events(OB,hc16gf1);
%load_events(HH,hc16hf1);

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
 keep education insurance DUPERSID PERWT97F VARSTR VARPSU;
run;

data stacked_events;
 set RX DV IP ER OP OB HH;
run;

proc sort data = stacked_events; by DUPERSID; run;
proc sort data = FYCsub; by DUPERSID; run;

data pers_events;
 merge stacked_events FYCsub;
 by DUPERSID;
 EXP = (XP97X >= 0);
run;

proc means data = pers_events sum noprint;
 by DUPERSID VARSTR VARPSU PERWT97F education insurance ;
 var EXP;
 output out = n_events sum = EXP;
run;

ods output Domain = out;
proc surveymeans data = n_events mean missing nobs;
 FORMAT education education. insurance insurance.;
 VAR EXP;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT97F;
 DOMAIN education*insurance;
run;

proc print data = out;
run;
