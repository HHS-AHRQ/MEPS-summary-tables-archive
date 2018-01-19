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

/* Race by sex */
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

 if sex = 2 then racesex = race*-1;
 else racesex = race;
run;

proc format;
 value racesex
 1 = "Male, Hispanic"
 2 = "Male, White"
 3 = "Male, Black"
 4 = "Male, Amer. Indian, AK Native, or mult. races"
 5 = "Male, Asian, Hawaiian, or Pacific Islander"
 9 = "Male, White and other"
 -1 = "Female, Hispanic"
 -2 = "Female, White"
 -3 = "Female, Black"
 -4 = "Female, Amer. Indian, AK Native, or mult. races"
 -5 = "Female, Asian, Hawaiian, or Pacific Islander"
 -9 = "Female, White and other"
 . = "Missing";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
 FORMAT racesex racesex. insurance insurance.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT00F;
 TABLES racesex*insurance / row;
run;

proc print data = out;
 where insurance ne . ;
 var domain racesex insurance Frequency WgtFreq StdDev RowPercent RowStdErr;
run;
