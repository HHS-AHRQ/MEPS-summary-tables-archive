ods graphics off;

/* Read in dataset and initialize year */
FILENAME h97 "C:\MEPS\h97.ssp";
proc xcopy in = h97 out = WORK IMPORT;
run;

data MEPS;
 SET h97;
 ARRAY OLDVAR(5) VARPSU05 VARSTR05 WTDPER05 AGE2X AGE1X;
 year = 2005;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU05;
  VARSTR = VARSTR05;
 end;

 if year <= 1998 then do;
  PERWT05F = WTDPER05;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE05X >= 0 then AGELAST = AGE05x;
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
  public   = (MCDEV05 = 1) or (OPAEV05=1) or (OPBEV05=1);
  medicare = (MCREV05=1);
  private  = (INSCOV05=1);

  mcr_priv = (medicare and  private);
  mcr_pub  = (medicare and ~private and public);
  mcr_only = (medicare and ~private and ~public);
  no_mcr   = (~medicare);

  ins_gt65 = 4*mcr_only + 5*mcr_priv + 6*mcr_pub + 7*no_mcr;

  if AGELAST < 65 then INSURC05 = INSCOV05;
  else INSURC05 = ins_gt65;
 end;

 insurance = INSCOV05;
 insurance_v2X = INSURC05;
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

/* Marital Status */
data MEPS; set MEPS;
 ARRAY OLDMAR(2) MARRY1X MARRY2X;
 if year = 1996 then do;
  if MARRY2X <= 6 then MARRY42X = MARRY2X;
  else MARRY42X = MARRY2X-6;

  if MARRY1X <= 6 then MARRY31X = MARRY1X;
  else MARRY31X = MARRY1X-6;
 end;

 if MARRY05X >= 0 then married = MARRY05X;
 else if MARRY42X >= 0 then married = MARRY42X;
 else if MARRY31X >= 0 then married = MARRY31X;
 else married = .;
run;

proc format;
 value married
 1 = "Married"
 2 = "Widowed"
 3 = "Divorced"
 4 = "Separated"
 5 = "Never married"
 6 = "Inapplicable (age < 16)"
 . = "Missing";
run;

data MEPS;
 set MEPS;
 domain = (AGELAST >= 65);
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
 FORMAT married married. insurance_v2X insurance_v2X.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT05F;
 TABLES domain*married*insurance_v2X / row;
run;

proc print data = out;
 where insurance_v2X ne . ;
 var domain married insurance_v2X Frequency WgtFreq StdDev RowPercent RowStdErr;
run;
