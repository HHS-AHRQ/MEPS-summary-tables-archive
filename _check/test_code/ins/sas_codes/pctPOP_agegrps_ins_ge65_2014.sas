ods graphics off;

/* Read in dataset and initialize year */
FILENAME h171 "C:\MEPS\h171.ssp";
proc xcopy in = h171 out = WORK IMPORT;
run;

data MEPS;
 SET h171;
 ARRAY OLDVAR(5) VARPSU14 VARSTR14 WTDPER14 AGE2X AGE1X;
 year = 2014;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU14;
  VARSTR = VARSTR14;
 end;

 if year <= 1998 then do;
  PERWT14F = WTDPER14;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE14X >= 0 then AGELAST = AGE14x;
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
  public   = (MCDEV14 = 1) or (OPAEV14=1) or (OPBEV14=1);
  medicare = (MCREV14=1);
  private  = (INSCOV14=1);

  mcr_priv = (medicare and  private);
  mcr_pub  = (medicare and ~private and public);
  mcr_only = (medicare and ~private and ~public);
  no_mcr   = (~medicare);

  ins_gt65 = 4*mcr_only + 5*mcr_priv + 6*mcr_pub + 7*no_mcr;

  if AGELAST < 65 then INSURC14 = INSCOV14;
  else INSURC14 = ins_gt65;
 end;

 insurance = INSCOV14;
 insurance_v2X = INSURC14;
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

/* Age groups */
/* To compute for all age groups, replace 'agegrps' in the SURVEY procedure with 'agegrps_v2X'  */
data MEPS; set MEPS;
 agegrps = AGELAST;
 agegrps_v2X = AGELAST;
 agegrps_v3X = AGELAST;
run;

proc format;
 value agegrps
 low-4 = "Under 5"
 5-17  = "5-17"
 18-44 = "18-44"
 45-64 = "45-64"
 65-high = "65+";

 value agegrps_v2X
 low-17  = "Under 18"
 18-64   = "18-64"
 65-high = "65+";

 value agegrps_v3X
 low-4 = "Under 5"
 5-6   = "5-6"
 7-12  = "7-12"
 13-17 = "13-17"
 18    = "18"
 19-24 = "19-24"
 25-29 = "25-29"
 30-34 = "30-34"
 35-44 = "35-44"
 45-54 = "45-54"
 55-64 = "55-64"
 65-high = "65+";
run;

data MEPS;
 set MEPS;
 domain = (AGELAST >= 65);
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
 FORMAT agegrps agegrps. insurance_v2X insurance_v2X.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT14F;
 TABLES domain*agegrps*insurance_v2X / row;
run;

proc print data = out;
 where insurance_v2X ne . ;
 var domain agegrps insurance_v2X Frequency WgtFreq StdDev RowPercent RowStdErr;
run;
