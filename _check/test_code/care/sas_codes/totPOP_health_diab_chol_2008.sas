ods graphics off;

/* Read in dataset and initialize year */
FILENAME h121 "C:\MEPS\h121.ssp";
proc xcopy in = h121 out = WORK IMPORT;
run;

data MEPS;
 SET h121;
 year = 2008;
 ind = 1;
 count = 1;

 /* Create AGELAST variable */
 if AGE08X >= 0 then AGELAST=AGE08x;
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

/*  Diabetes care: Lipid profile */
data MEPS; set MEPS;
 ARRAY CHLVAR(5) CHOLCK53 DSCHNV53 DSCH0753 DSCH0853 DSCH0953;
 if year > 2007 then do;
  past_year = (DSCH0853=1 or DSCH0953=1);
  more_year = (DSCH0753=1 or DSCB0753=1);
  never_chk = (DSCHNV53 = 1);
  non_resp  = (DSCH0853 in (-7,-8,-9));
 end;

 else do;
  past_year = (CHOLCK53 = 1);
  more_year = (1 < CHOLCK53 and CHOLCK53 < 6);
  never_chk = (CHOLCK53 = 6);
  non_resp  = (CHOLCK53 in (-7,-8,-9));
 end;

 if past_year = 1 then diab_chol = 1;
 else if more_year = 1 then diab_chol = 2;
 else if never_chk = 1 then diab_chol = 3;
 else if non_resp = 1  then diab_chol = -7;
 else diab_chol = -9;

 if diabw08f>0 then domain=1;
 else do;
   domain=2;
   diabw08f=1;
 end;
run;

proc format;
 value diab_chol
  1 = "In the past year"
  2 = "More than 1 year ago"
  3 = "Never had cholesterol checked"
  4 = "No exam in past year"
 -1 = "Inapplicable"
 -7 = "Don't know/Non-response"
 -9 = "Missing";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
 FORMAT diab_chol diab_chol. health health.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT DIABW08F;
 TABLES domain*health*diab_chol / row;
run;

proc print data = out;
 where domain = 1 and diab_chol ne . and health ne .;
 var diab_chol health WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
