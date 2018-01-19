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
 FORMAT delay: delay. ind ind.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT02F;
 TABLES domain*ind*(delay_ANY delay_MD delay_DN delay_PM) / row;
run;

proc print data = out;
 where domain = 1 and (delay_ANY > 0 or delay_MD > 0 or delay_DN > 0 or delay_PM > 0) and ind ne .;
 var delay_ANY delay_MD delay_DN delay_PM ind WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
