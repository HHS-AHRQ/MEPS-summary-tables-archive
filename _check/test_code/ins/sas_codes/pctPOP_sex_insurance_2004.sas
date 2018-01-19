ods graphics off;

/* Read in dataset and initialize year */
FILENAME h89 "C:\MEPS\h89.ssp";
proc xcopy in = h89 out = WORK IMPORT;
run;

data MEPS;
 SET h89;
 ARRAY OLDVAR(5) VARPSU04 VARSTR04 WTDPER04 AGE2X AGE1X;
 year = 2004;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU04;
  VARSTR = VARSTR04;
 end;

 if year <= 1998 then do;
  PERWT04F = WTDPER04;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE04X >= 0 then AGELAST = AGE04x;
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
  public   = (MCDEV04 = 1) or (OPAEV04=1) or (OPBEV04=1);
  medicare = (MCREV04=1);
  private  = (INSCOV04=1);

  mcr_priv = (medicare and  private);
  mcr_pub  = (medicare and ~private and public);
  mcr_only = (medicare and ~private and ~public);
  no_mcr   = (~medicare);

  ins_gt65 = 4*mcr_only + 5*mcr_priv + 6*mcr_pub + 7*no_mcr;

  if AGELAST < 65 then INSURC04 = INSCOV04;
  else INSURC04 = ins_gt65;
 end;

 insurance = INSCOV04;
 insurance_v2X = INSURC04;
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

/* Sex */
proc format;
 value sex
 1 = "Male"
 2 = "Female";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
 FORMAT sex sex. insurance insurance.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT04F;
 TABLES sex*insurance / row;
run;

proc print data = out;
 where insurance ne . ;
 var domain sex insurance Frequency WgtFreq StdDev RowPercent RowStdErr;
run;
