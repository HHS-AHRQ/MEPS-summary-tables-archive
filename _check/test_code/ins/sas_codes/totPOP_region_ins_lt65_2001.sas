ods graphics off;

/* Read in dataset and initialize year */
FILENAME h60 "C:\MEPS\h60.ssp";
proc xcopy in = h60 out = WORK IMPORT;
run;

data MEPS;
 SET h60;
 ARRAY OLDVAR(5) VARPSU01 VARSTR01 WTDPER01 AGE2X AGE1X;
 year = 2001;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU01;
  VARSTR = VARSTR01;
 end;

 if year <= 1998 then do;
  PERWT01F = WTDPER01;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE01X >= 0 then AGELAST = AGE01x;
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
  public   = (MCDEV01 = 1) or (OPAEV01=1) or (OPBEV01=1);
  medicare = (MCREV01=1);
  private  = (INSCOV01=1);

  mcr_priv = (medicare and  private);
  mcr_pub  = (medicare and ~private and public);
  mcr_only = (medicare and ~private and ~public);
  no_mcr   = (~medicare);

  ins_gt65 = 4*mcr_only + 5*mcr_priv + 6*mcr_pub + 7*no_mcr;

  if AGELAST < 65 then INSURC01 = INSCOV01;
  else INSURC01 = ins_gt65;
 end;

 insurance = INSCOV01;
 insurance_v2X = INSURC01;
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

 if REGION01 >= 0 then region = REGION01;
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
 WEIGHT PERWT01F;
 TABLES domain*region*insurance_v2X / row;
run;

proc print data = out;
 where insurance_v2X ne . ;
 var domain region insurance_v2X Frequency WgtFreq StdDev RowPercent RowStdErr;
run;
