ods graphics off;

/* Read in dataset and initialize year */
FILENAME h171 "C:\MEPS\h171.ssp";
proc xcopy in = h171 out = WORK IMPORT;
run;

data MEPS;
 SET h171;
 year = 2014;
 ind = 1;
 count = 1;

 /* Create AGELAST variable */
 if AGE14X >= 0 then AGELAST=AGE14x;
 else if AGE42X >= 0 then AGELAST=AGE42X;
 else if AGE31X >= 0 then AGELAST=AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Poverty status */
data MEPS; set MEPS;
 ARRAY OLDPOV(1) POVCAT;
 if year = 1996 then POVCAT96 = POVCAT;
 poverty = POVCAT14;
run;

proc format;
 value poverty
 1 = "Negative or poor"
 2 = "Near-poor"
 3 = "Low income"
 4 = "Middle income"
 5 = "High income";
run;

/* How often doctor showed respect (adults) */
data MEPS; set MEPS;
 adult_respect = ADRESP42;
 domain = (ADAPPT42 >= 1 & AGELAST >= 18);
 if domain = 0 and SAQWT14F = 0 then SAQWT14F = 1;
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
 FORMAT adult_respect freq. poverty poverty.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT SAQWT14F;
 TABLES domain*poverty*adult_respect / row;
run;

proc print data = out;
 where domain = 1 and adult_respect ne . and poverty ne .;
 var adult_respect poverty WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
