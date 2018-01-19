ods graphics off;

/* Read in dataset and initialize year */
FILENAME h181 "C:\MEPS\h181.ssp";
proc xcopy in = h181 out = WORK IMPORT;
run;

data MEPS;
 SET h181;
 ARRAY OLDVAR(5) VARPSU15 VARSTR15 WTDPER15 AGE2X AGE1X;
 year = 2015;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU15;
  VARSTR = VARSTR15;
 end;

 if year <= 1998 then do;
  PERWT15F = WTDPER15;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE15X >= 0 then AGELAST = AGE15x;
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
  public   = (MCDEV15 = 1) or (OPAEV15=1) or (OPBEV15=1);
  medicare = (MCREV15=1);
  private  = (INSCOV15=1);

  mcr_priv = (medicare and  private);
  mcr_pub  = (medicare and ~private and public);
  mcr_only = (medicare and ~private and ~public);
  no_mcr   = (~medicare);

  ins_gt65 = 4*mcr_only + 5*mcr_priv + 6*mcr_pub + 7*no_mcr;

  if AGELAST < 65 then INSURC15 = INSCOV15;
  else INSURC15 = ins_gt65;
 end;

 insurance = INSCOV15;
 insurance_v2X = INSURC15;
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

/* Race/ethnicity */
data MEPS; set MEPS;
 ARRAY RCEVAR(4) RACETHX RACEV1X RACETHNX RACEX;
 if year >= 2012 then do;
  hisp   = (RACETHX = 1);
   white  = (RACETHX = 2);
       black  = (RACETHX = 3);
       native = (RACETHX > 3 and RACEV1X in (3,6));
       asian  = (RACETHX > 3 and RACEV1X in (4,5));
  white_oth = 0;
 end;

 else if year >= 2002 then do;
  hisp   = (RACETHNX = 1);
  white  = (RACETHNX = 4 and RACEX = 1);
  black  = (RACETHNX = 2);
  native = (RACETHNX >= 3 and RACEX in (3,6));
  asian  = (RACETHNX >= 3 and RACEX in (4,5));
  white_oth = 0;
 end;

 else do;
  hisp  = (RACETHNX = 1);
  black = (RACETHNX = 2);
  white_oth = (RACETHNX = 3);
  white  = 0;
  native = 0;
  asian  = 0;
 end;

 race = 1*hisp + 2*white + 3*black + 4*native + 5*asian + 9*white_oth;
run;

proc format;
 value race
 1 = "Hispanic"
 2 = "White"
 3 = "Black"
 4 = "Amer. Indian, AK Native, or mult. races"
 5 = "Asian, Hawaiian, or Pacific Islander"
 9 = "White and other"
 . = "Missing";
run;

data MEPS;
 set MEPS;
 domain = (AGELAST < 65);
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
 FORMAT race race. insurance_v2X insurance_v2X.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT15F;
 TABLES domain*race*insurance_v2X / row;
run;

proc print data = out;
 where insurance_v2X ne . ;
 var domain race insurance_v2X Frequency WgtFreq StdDev RowPercent RowStdErr;
run;
