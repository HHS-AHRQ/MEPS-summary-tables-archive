ods graphics off;

/* Read in dataset and initialize year */
FILENAME h105 "C:\MEPS\h105.ssp";
proc xcopy in = h105 out = WORK IMPORT;
run;

data MEPS;
 SET h105;
 year = 2006;
 ind = 1;
 count = 1;

 /* Create AGELAST variable */
 if AGE06X >= 0 then AGELAST=AGE06x;
 else if AGE42X >= 0 then AGELAST=AGE42X;
 else if AGE31X >= 0 then AGELAST=AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Census Region */
data MEPS; set MEPS;
 ARRAY OLDREG(2) REGION1 REGION2;
 if year = 1996 then do;
  REGION42 = REGION2;
  REGION31 = REGION1;
 end;

 if REGION06 >= 0 then region = REGION06;
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

/* How often doctor explained things (adults) */
data MEPS; set MEPS;
 adult_explain = ADEXPL42;
 domain = (ADAPPT42 >= 1 & AGELAST >= 18);
 if domain = 0 and SAQWT06F = 0 then SAQWT06F = 1;
run;


proc format;
  value freq
   4 = "Always"
   3 = "Usually"
   2 = "Sometimes/Never"
   1 = "Sometimes/Never"
  -7 = "Don't know/Non-response"
  -8 = "Don't know/Non-response"
  -9 = "Don't know/Non-response"
  -1 = "Inapplicable"
  . = "Missing";
run;


ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
 FORMAT adult_explain freq. region region.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT SAQWT06F;
 TABLES domain*region*adult_explain / row;
run;

proc print data = out;
 where domain = 1 and adult_explain ne . and region ne .;
 var adult_explain region WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
