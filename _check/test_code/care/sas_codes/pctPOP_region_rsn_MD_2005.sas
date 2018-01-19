ods graphics off;

/* Read in dataset and initialize year */
FILENAME h97 "C:\MEPS\h97.ssp";
proc xcopy in = h97 out = WORK IMPORT;
run;

data MEPS;
 SET h97;
 year = 2005;
 ind = 1;
 count = 1;

 /* Create AGELAST variable */
 if AGE05X >= 0 then AGELAST=AGE05x;
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

 if REGION05 >= 0 then region = REGION05;
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
 FORMAT afford_MD afford. insure_MD insure. other_MD other. region region.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT05F;
 TABLES domain*region*(afford_MD insure_MD other_MD) / row;
run;

proc print data = out;
 where domain = 1 and (afford_MD > 0 or insure_MD > 0 or other_MD > 0) and region ne .;
 var afford_MD insure_MD other_MD region WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
