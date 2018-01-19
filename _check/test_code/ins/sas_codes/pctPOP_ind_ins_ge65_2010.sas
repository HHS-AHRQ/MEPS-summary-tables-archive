ods graphics off;

/* Read in dataset and initialize year */
FILENAME h138 "C:\MEPS\h138.ssp";
proc xcopy in = h138 out = WORK IMPORT;
run;

data MEPS;
 SET h138;
 ARRAY OLDVAR(5) VARPSU10 VARSTR10 WTDPER10 AGE2X AGE1X;
 year = 2010;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU10;
  VARSTR = VARSTR10;
 end;

 if year <= 1998 then do;
  PERWT10F = WTDPER10;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE10X >= 0 then AGELAST = AGE10x;
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
  public   = (MCDEV10 = 1) or (OPAEV10=1) or (OPBEV10=1);
  medicare = (MCREV10=1);
  private  = (INSCOV10=1);

  mcr_priv = (medicare and  private);
  mcr_pub  = (medicare and ~private and public);
  mcr_only = (medicare and ~private and ~public);
  no_mcr   = (~medicare);

  ins_gt65 = 4*mcr_only + 5*mcr_priv + 6*mcr_pub + 7*no_mcr;

  if AGELAST < 65 then INSURC10 = INSCOV10;
  else INSURC10 = ins_gt65;
 end;

 insurance = INSCOV10;
 insurance_v2X = INSURC10;
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

data MEPS;
 set MEPS;
 domain = (AGELAST >= 65);
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
 FORMAT ind ind. insurance_v2X insurance_v2X.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT10F;
 TABLES domain*ind*insurance_v2X / row;
run;

proc print data = out;
 where insurance_v2X ne . ;
 var domain ind insurance_v2X Frequency WgtFreq StdDev RowPercent RowStdErr;
run;
