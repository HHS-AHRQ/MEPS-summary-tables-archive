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

/* Reason for difficulty receiving needed prescribed medicines */
data MEPS; set MEPS;
 delay_PM  = (PMUNAB42=1|PMDLAY42=1);
 afford_PM = (PMDLRS42=1|PMUNRS42=1);
 insure_PM = (PMDLRS42 in (2,3)|PMUNRS42 in (2,3));
 other_PM  = (PMDLRS42 > 3|PMUNRS42 > 3);
 domain = (ACCELI42 = 1 & delay_PM=1);
run;

proc format;
 value afford 1 = "Couldn't afford";
 value insure 1 = "Insurance related";
 value other 1 = "Other";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
 FORMAT afford_PM afford. insure_PM insure. other_PM other. health health.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT09F;
 TABLES domain*health*(afford_PM insure_PM other_PM) / row;
run;

proc print data = out;
 where domain = 1 and (afford_PM > 0 or insure_PM > 0 or other_PM > 0) and health ne .;
 var afford_PM insure_PM other_PM health WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
