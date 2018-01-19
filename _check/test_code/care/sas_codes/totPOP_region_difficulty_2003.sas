ods graphics off;

/* Read in dataset and initialize year */
FILENAME h79 "C:\MEPS\h79.ssp";
proc xcopy in = h79 out = WORK IMPORT;
run;

data MEPS;
 SET h79;
 year = 2003;
 ind = 1;
 count = 1;

 /* Create AGELAST variable */
 if AGE03X >= 0 then AGELAST=AGE03x;
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

 if REGION03 >= 0 then region = REGION03;
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

/* Difficulty receiving needed care */
data MEPS; set MEPS;
 delay_MD = (MDUNAB42 = 1|MDDLAY42=1);
 delay_DN = (DNUNAB42 = 1|DNDLAY42=1);
 delay_PM = (PMUNAB42 = 1|PMDLAY42=1);
 delay_ANY = (delay_MD|delay_DN|delay_PM);
 domain = (ACCELI42 = 1);
run;

proc format;
 value delay
 1 = "Difficulty accessing care"
 0 = "No difficulty";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
 FORMAT delay: delay. region region.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT03F;
 TABLES domain*region*(delay_ANY delay_MD delay_DN delay_PM) / row;
run;

proc print data = out;
 where domain = 1 and (delay_ANY > 0 or delay_MD > 0 or delay_DN > 0 or delay_PM > 0) and region ne .;
 var delay_ANY delay_MD delay_DN delay_PM region WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
