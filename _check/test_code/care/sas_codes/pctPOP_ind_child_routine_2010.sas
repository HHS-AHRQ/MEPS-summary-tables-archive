ods graphics off;

/* Read in dataset and initialize year */
FILENAME h138 "C:\MEPS\h138.ssp";
proc xcopy in = h138 out = WORK IMPORT;
run;

data MEPS;
 SET h138;
 year = 2010;
 ind = 1;
 count = 1;

 /* Create AGELAST variable */
 if AGE10X >= 0 then AGELAST=AGE10x;
 else if AGE42X >= 0 then AGELAST=AGE42X;
 else if AGE31X >= 0 then AGELAST=AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Ability to schedule a routine appt. (children) */
data MEPS; set MEPS;
 child_routine = CHRTWW42;
 domain = (CHRTCR42 = 1 & AGELAST < 18);
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
 FORMAT child_routine freq. ind ind.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT10F;
 TABLES domain*ind*child_routine / row;
run;

proc print data = out;
 where domain = 1 and child_routine ne . and ind ne .;
 var child_routine ind WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
