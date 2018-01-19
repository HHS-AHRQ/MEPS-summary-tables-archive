ods graphics off;

/* Read in dataset and initialize year */
FILENAME h129 "C:\MEPS\h129.ssp";
proc xcopy in = h129 out = WORK IMPORT;
run;

data MEPS;
 SET h129;
 year = 2009;
 ind = 1;
 count = 1;

 /* Create AGELAST variable */
 if AGE09X >= 0 then AGELAST=AGE09x;
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
 poverty = POVCAT09;
run;

proc format;
 value poverty
 1 = "Negative or poor"
 2 = "Near-poor"
 3 = "Low income"
 4 = "Middle income"
 5 = "High income";
run;

/* Children receiving dental care */
data MEPS; set MEPS;
 child_dental = (DVTOT09 > 0);
 domain = (1 < AGELAST & AGELAST < 18);
run;

proc format;
 value child_dental
 1 = "One or more dental visits"
 0 = "No dental visits in past year";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
 FORMAT child_dental child_dental. poverty poverty.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT09F;
 TABLES domain*poverty*child_dental / row;
run;

proc print data = out;
 where domain = 1 and child_dental ne . and poverty ne .;
 var child_dental poverty WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
