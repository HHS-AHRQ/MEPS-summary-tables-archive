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

/* Children receiving dental care */
data MEPS; set MEPS;
 child_dental = (DVTOT03 > 0);
 domain = (1 < AGELAST & AGELAST < 18);
run;

proc format;
 value child_dental
 1 = "One or more dental visits"
 0 = "No dental visits in past year";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
 FORMAT child_dental child_dental. health health.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT03F;
 TABLES domain*health*child_dental / row;
run;

proc print data = out;
 where domain = 1 and child_dental ne . and health ne .;
 var child_dental health WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
