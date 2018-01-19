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

/* Rating for care (adults) */
data MEPS; set MEPS;
 adult_rating = ADHECR42;
 domain = (ADAPPT42 >= 1 & AGELAST >= 18);
 if domain = 0 and SAQWT05F = 0 then SAQWT05F = 1;
run;

proc format;
 value adult_rating
 9-10 = "9-10 rating"
 7-8 = "7-8 rating"
 0-6 = "0-6 rating"
 -9 - -7 = "Don't know/Non-response"
 -1 = "Inapplicable";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
 FORMAT adult_rating adult_rating. health health.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT SAQWT05F;
 TABLES domain*health*adult_rating / row;
run;

proc print data = out;
 where domain = 1 and adult_rating ne . and health ne .;
 var adult_rating health WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
