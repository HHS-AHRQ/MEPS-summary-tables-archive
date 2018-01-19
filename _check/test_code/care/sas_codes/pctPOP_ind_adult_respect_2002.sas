ods graphics off;

/* Read in dataset and initialize year */
FILENAME h70 "C:\MEPS\h70.ssp";
proc xcopy in = h70 out = WORK IMPORT;
run;

data MEPS;
 SET h70;
 year = 2002;
 ind = 1;
 count = 1;

 /* Create AGELAST variable */
 if AGE02X >= 0 then AGELAST=AGE02x;
 else if AGE42X >= 0 then AGELAST=AGE42X;
 else if AGE31X >= 0 then AGELAST=AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* How often doctor showed respect (adults) */
data MEPS; set MEPS;
 adult_respect = ADRESP42;
 domain = (ADAPPT42 >= 1 & AGELAST >= 18);
 if domain = 0 and SAQWT02F = 0 then SAQWT02F = 1;
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
 FORMAT adult_respect freq. ind ind.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT SAQWT02F;
 TABLES domain*ind*adult_respect / row;
run;

proc print data = out;
 where domain = 1 and adult_respect ne . and ind ne .;
 var adult_respect ind WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
