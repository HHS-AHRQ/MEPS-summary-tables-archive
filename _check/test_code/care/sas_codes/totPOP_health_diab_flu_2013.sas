ods graphics off;

/* Read in dataset and initialize year */
FILENAME h163 "C:\MEPS\h163.ssp";
proc xcopy in = h163 out = WORK IMPORT;
run;

data MEPS;
 SET h163;
 year = 2013;
 ind = 1;
 count = 1;

 /* Create AGELAST variable */
 if AGE13X >= 0 then AGELAST=AGE13x;
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

/* Diabetes care: Flu shot */
data MEPS; set MEPS;
 ARRAY FLUVAR(5) FLUSHT53 DSFLNV53 DSFL1253 DSFL1353 DSFL1453;
 if year > 2007 then do;
  past_year = (DSFL1353=1 | DSFL1453=1);
  more_year = (DSFL1253=1 | DSVB1253=1);
  never_chk = (DSFLNV53 = 1);
  non_resp  = (DSFL1353 in (-7,-8,-9));
 end;

 else do;
  past_year = (FLUSHT53 = 1);
  more_year = (1 < FLUSHT53 & FLUSHT53 < 6);
  never_chk = (FLUSHT53 = 6);
  non_resp  = (FLUSHT53 in (-7,-8,-9));
 end;

 if past_year = 1 then diab_flu = 1;
 else if more_year = 1 then diab_flu = 2;
 else if never_chk = 1 then diab_flu = 3;
 else if non_resp = 1  then diab_flu = -7;
 else diab_flu = -9;

 if diabw13f>0 then domain=1;
 else do;
   domain=2;
   diabw13f=1;
 end;
run;

proc format;
 value diab_flu
  1 = "In the past year"
  2 = "More than 1 year ago"
  3 = "Never had flu shot"
  4 = "No flu shot in past year"
 -1 = "Inapplicable"
 -7 = "Don't know/Non-response"
 -9 = "Missing";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
 FORMAT diab_flu diab_flu. health health.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT DIABW13F;
 TABLES domain*health*diab_flu / row;
run;

proc print data = out;
 where domain = 1 and diab_flu ne . and health ne .;
 var diab_flu health WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
