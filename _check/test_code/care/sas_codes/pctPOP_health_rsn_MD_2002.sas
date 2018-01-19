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

/* Perceived health status */
data MEPS; set MEPS;
 ARRAY OLDHLT(2) RTEHLTH1 RTEHLTH2;
 if year = 1996 then do;
  RTHLTH53 = RTEHLTH2;
  RTHLTH42 = RTEHLTH2;
  RTHLTH31 = RTEHLTH1;
 end;

 if RTHLTH53 >= 0 then health = RTHLTH53;
 else if RTHLTH42 >= 0 then health = RTHLTH42;
 else if RTHLTH31 >= 0 then health = RTHLTH31;
 else health = .;
run;

proc format;
 value health
 1 = "Excellent"
 2 = "Very good"
 3 = "Good"
 4 = "Fair"
 5 = "Poor"
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
 FORMAT afford_MD afford. insure_MD insure. other_MD other. health health.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT02F;
 TABLES domain*health*(afford_MD insure_MD other_MD) / row;
run;

proc print data = out;
 where domain = 1 and (afford_MD > 0 or insure_MD > 0 or other_MD > 0) and health ne .;
 var afford_MD insure_MD other_MD health WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
