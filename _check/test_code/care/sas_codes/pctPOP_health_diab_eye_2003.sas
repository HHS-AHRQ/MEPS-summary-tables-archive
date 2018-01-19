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

/* Diabetes care: Eye exam */
data MEPS; set MEPS;

 past_year = (DSEY0353=1 | DSEY0453=1);
 more_year = (DSEY0253=1 | DSEB0253=1);
 never_chk = (DSEYNV53 = 1);
 non_resp = (DSEY0353 in (-7,-8,-9));

 if past_year = 1 then diab_eye = 1;
 else if more_year = 1 then diab_eye = 2;
 else if never_chk = 1 then diab_eye = 3;
 else if non_resp = 1  then diab_eye = -7;
 else diab_eye = -9;

 if diabw03f>0 then domain=1;
 else do;
   domain=2;
   diabw03f=1;
 end;
run;

proc format;
 value diab_eye
  1 = "In the past year"
  2 = "More than 1 year ago"
  3 = "Never had eye exam"
  4 = "No exam in past year"
 -1 = "Inapplicable"
 -7 = "Don't know/Non-response"
 -9 = "Missing";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
 FORMAT diab_eye diab_eye. health health.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT DIABW03F;
 TABLES domain*health*diab_eye / row;
run;

proc print data = out;
 where domain = 1 and diab_eye ne . and health ne .;
 var diab_eye health WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
