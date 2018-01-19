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

/* Poverty status */
data MEPS; set MEPS;
 ARRAY OLDPOV(1) POVCAT;
 if year = 1996 then POVCAT96 = POVCAT;
 poverty = POVCAT09;
run;

proc format;
 value poverty
 1 = "Negative or poor"
 2 = "Near-poor"
 3 = "Low income"
 4 = "Middle income"
 5 = "High income";
run;

/* Diabetes care: Eye exam */
data MEPS; set MEPS;

 past_year = (DSEY0953=1 | DSEY1053=1);
 more_year = (DSEY0853=1 | DSEB0853=1);
 never_chk = (DSEYNV53 = 1);
 non_resp = (DSEY0953 in (-7,-8,-9));

 if past_year = 1 then diab_eye = 1;
 else if more_year = 1 then diab_eye = 2;
 else if never_chk = 1 then diab_eye = 3;
 else if non_resp = 1  then diab_eye = -7;
 else diab_eye = -9;

 if diabw09f>0 then domain=1;
 else do;
   domain=2;
   diabw09f=1;
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
 FORMAT diab_eye diab_eye. poverty poverty.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT DIABW09F;
 TABLES domain*poverty*diab_eye / row;
run;

proc print data = out;
 where domain = 1 and diab_eye ne . and poverty ne .;
 var diab_eye poverty WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
