ods graphics off;

/* Read in dataset and initialize year */
FILENAME h28 "C:\MEPS\h28.ssp";
proc xcopy in = h28 out = WORK IMPORT;
run;

data MEPS;
 SET h28;
 ARRAY OLDVAR(5) VARPSU98 VARSTR98 WTDPER98 AGE2X AGE1X;
 year = 1998;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU98;
  VARSTR = VARSTR98;
 end;

 if year <= 1998 then do;
  PERWT98F = WTDPER98;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE98X >= 0 then AGELAST = AGE98x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Education */
data MEPS; set MEPS;
 ARRAY EDUVARS(4) EDUCYR98 EDUCYR EDUCYEAR EDRECODE;
 if year <= 1998 then EDUCYR = EDUCYR98;
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
  year = 1998;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH98X &evnt.FCH98X SEEDOC ;
   SF98X = &evnt.DSF98X + &evnt.FSF98X;
   MR98X = &evnt.DMR98X + &evnt.FMR98X;
   MD98X = &evnt.DMD98X + &evnt.FMD98X;
   PV98X = &evnt.DPV98X + &evnt.FPV98X;
   VA98X = &evnt.DVA98X + &evnt.FVA98X;
   OF98X = &evnt.DOF98X + &evnt.FOF98X;
   SL98X = &evnt.DSL98X + &evnt.FSL98X;
   WC98X = &evnt.DWC98X + &evnt.FWC98X;
   OR98X = &evnt.DOR98X + &evnt.FOR98X;
   OU98X = &evnt.DOU98X + &evnt.FOU98X;
   OT98X = &evnt.DOT98X + &evnt.FOT98X;
   XP98X = &evnt.DXP98X + &evnt.FXP98X;

   if year <= 1999 then TR98X = &evnt.DCH98X + &evnt.FCH98X;
   else TR98X = &evnt.DTR98X + &evnt.FTR98X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH98X SEEDOC ;
   SF98X = &evnt.SF98X;
   MR98X = &evnt.MR98X;
   MD98X = &evnt.MD98X;
   PV98X = &evnt.PV98X;
   VA98X = &evnt.VA98X;
   OF98X = &evnt.OF98X;
   SL98X = &evnt.SL98X;
   WC98X = &evnt.WC98X;
   OR98X = &evnt.OR98X;
   OU98X = &evnt.OU98X;
   OT98X = &evnt.OT98X;
   XP98X = &evnt.XP98X;

   if year <= 1999 then TR98X = &evnt.CH98X;
   else TR98X = &evnt.TR98X;
  %end;

  PR98X = PV98X + TR98X;
  OZ98X = OF98X + SL98X + OT98X + OR98X + OU98X + WC98X + VA98X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP98X SF98X PR98X MR98X MD98X OZ98X;
 run;
%mend;

%load_events(RX,h26a);
%load_events(DV,hc26bf1);
%load_events(IP,h26df1);
%load_events(ER,h26ef1);
%load_events(OP,h26ff1);
%load_events(OB,h26gf1);
%load_events(HH,h26hf1);

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
 keep education DUPERSID PERWT98F VARSTR VARPSU;
run;

data stacked_events;
 set RX DV IP ER OP OB HH;
run;

proc sort data = stacked_events; by DUPERSID; run;
proc sort data = FYCsub; by DUPERSID; run;

data pers_events;
 merge stacked_events FYCsub;
 by DUPERSID;
 EXP = (XP98X > 0);
 SLF = (SF98X > 0);
 MCR = (MR98X > 0);
 MCD = (MD98X > 0);
 PTR = (PR98X > 0);
 OTZ = (OZ98X > 0);
run;

proc means data = pers_events sum noprint;
 by DUPERSID VARSTR VARPSU PERWT98F education;
 var EXP SLF MCR MCD PTR OTZ;
 output out = n_events sum = EXP SLF MCR MCD PTR OTZ;
run;

ods output Domain = out;
proc surveymeans data = n_events mean missing nobs;
 FORMAT education education.;
 VAR EXP SLF MCR MCD PTR OTZ;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT98F;
 DOMAIN education;
run;

proc print data = out;
run;
