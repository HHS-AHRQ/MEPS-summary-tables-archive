ods graphics off;

/* Read in dataset and initialize year */
FILENAME h129 "C:\MEPS\h129.ssp";
proc xcopy in = h129 out = WORK IMPORT;
run;

data MEPS;
 SET h129;
 ARRAY OLDVAR(5) VARPSU09 VARSTR09 WTDPER09 AGE2X AGE1X;
 year = 2009;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU09;
  VARSTR = VARSTR09;
 end;

 if year <= 1998 then do;
  PERWT09F = WTDPER09;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE09X >= 0 then AGELAST = AGE09x;
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
  public   = (MCDEV09 = 1) or (OPAEV09=1) or (OPBEV09=1);
  medicare = (MCREV09=1);
  private  = (INSCOV09=1);

  mcr_priv = (medicare and  private);
  mcr_pub  = (medicare and ~private and public);
  mcr_only = (medicare and ~private and ~public);
  no_mcr   = (~medicare);

  ins_gt65 = 4*mcr_only + 5*mcr_priv + 6*mcr_pub + 7*no_mcr;

  if AGELAST < 65 then INSURC09 = INSCOV09;
  else INSURC09 = ins_gt65;
 end;

 insurance = INSCOV09;
 insurance_v2X = INSURC09;
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

/* Census Region */
data MEPS; set MEPS;
 ARRAY OLDREG(2) REGION1 REGION2;
 if year = 1996 then do;
  REGION42 = REGION2;
  REGION31 = REGION1;
 end;

 if REGION09 >= 0 then region = REGION09;
 else if REGION42 >= 0 then region = REGION42;
 else if REGION31 >= 0 then region = REGION31;
 else region = .;
run;

proc format;
 value region
 1 = "Northeast"
 2 = "Midwest"
 3 = "South"
 4 = "West"
 . = "Missing";
run;

data MEPS;
 set MEPS;
 domain = (AGELAST < 65);
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
 FORMAT region region. insurance_v2X insurance_v2X.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT09F;
 TABLES domain*region*insurance_v2X / row;
run;

proc print data = out;
 where insurance_v2X ne . ;
 var domain region insurance_v2X Frequency WgtFreq StdDev RowPercent RowStdErr;
run;
