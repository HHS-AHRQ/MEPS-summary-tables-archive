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

/* Census Region */
data MEPS; set MEPS;
 ARRAY OLDREG(2) REGION1 REGION2;
 if year = 1996 then do;
  REGION42 = REGION2;
  REGION31 = REGION1;
 end;

 if REGION02 >= 0 then region = REGION02;
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

/* Diabetes care: Flu shot */
data MEPS; set MEPS;
 ARRAY FLUVAR(5) FLUSHT53 DSFLNV53 DSFL0153 DSFL0253 DSFL0353;
 if year > 2007 then do;
  past_year = (DSFL0253=1 | DSFL0353=1);
  more_year = (DSFL0153=1 | DSVB0153=1);
  never_chk = (DSFLNV53 = 1);
  non_resp  = (DSFL0253 in (-7,-8,-9));
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

 if diabw02f>0 then domain=1;
 else do;
   domain=2;
   diabw02f=1;
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
 FORMAT diab_flu diab_flu. region region.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT DIABW02F;
 TABLES domain*region*diab_flu / row;
run;

proc print data = out;
 where domain = 1 and diab_flu ne . and region ne .;
 var diab_flu region WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
