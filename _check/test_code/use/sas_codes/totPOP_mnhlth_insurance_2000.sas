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

/* Perceived mental health */
data MEPS; set MEPS;
 ARRAY OLDMNH(2) MNTHLTH1 MNTHLTH2;
 if year = 1996 then do;
  MNHLTH53 = MNTHLTH2;
  MNHLTH42 = MNTHLTH2;
  MNHLTH31 = MNTHLTH1;
 end;

 if MNHLTH53 ge 0 then mnhlth = MNHLTH53;
 else if MNHLTH42 ge 0 then mnhlth = MNHLTH42;
 else if MNHLTH31 ge 0 then mnhlth = MNHLTH31;
 else mnhlth = .;
run;

proc format;
 value mnhlth
 1 = "Excellent"
 2 = "Very good"
 3 = "Good"
 4 = "Fair"
 5 = "Poor"
 . = "Missing";
run;

ods output Domain = out;
proc surveymeans data = MEPS sum missing nobs;
 FORMAT mnhlth mnhlth. insurance insurance.;
 VAR count;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT00F;
 DOMAIN mnhlth*insurance;
run;

proc print data = out;
run;
