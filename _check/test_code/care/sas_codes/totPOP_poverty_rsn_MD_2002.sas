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

/* Poverty status */
data MEPS; set MEPS;
 ARRAY OLDPOV(1) POVCAT;
 if year = 1996 then POVCAT96 = POVCAT;
 poverty = POVCAT02;
run;

proc format;
 value poverty
 1 = "Negative or poor"
 2 = "Near-poor"
 3 = "Low income"
 4 = "Middle income"
 5 = "High income";
run;

/* Reason for difficulty receiving needed medical care */
data MEPS; set MEPS;
 delay_MD  = (MDUNAB42=1|MDDLAY42=1);
 afford_MD = (MDDLRS42=1|MDUNRS42=1);
 insure_MD = (MDDLRS42 in (2,3)|MDUNRS42 in (2,3));
 other_MD  = (MDDLRS42 > 3|MDUNRS42 > 3);
 domain = (ACCELI42 = 1 & delay_MD=1);
run;

proc format;
 value afford 1 = "Couldn't afford";
 value insure 1 = "Insurance related";
 value other 1 = "Other";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
 FORMAT afford_MD afford. insure_MD insure. other_MD other. poverty poverty.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT02F;
 TABLES domain*poverty*(afford_MD insure_MD other_MD) / row;
run;

proc print data = out;
 where domain = 1 and (afford_MD > 0 or insure_MD > 0 or other_MD > 0) and poverty ne .;
 var afford_MD insure_MD other_MD poverty WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
