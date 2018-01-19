ods graphics off;

/* Read in dataset and initialize year */
FILENAME h70 "C:\MEPS\h70.ssp";
proc xcopy in = h70 out = WORK IMPORT;
run;

data MEPS;
 SET h70;
 ARRAY OLDVAR(5) VARPSU02 VARSTR02 WTDPER02 AGE2X AGE1X;
 year = 2002;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU02;
  VARSTR = VARSTR02;
 end;

 if year <= 1998 then do;
  PERWT02F = WTDPER02;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE02X >= 0 then AGELAST = AGE02x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
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

data MEPS_gt0; set MEPS;
  TOTEXP02 = (TOTEXP02 > 0);
run;

ods output Domain = out;
proc surveymeans data = MEPS_gt0 mean missing nobs;
 FORMAT race race. ind ind.;
 VAR TOTEXP02;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT02F;
 DOMAIN race*ind;
run;

proc print data = out;
run;
