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

/* Employment Status */
data MEPS; set MEPS;
 ARRAY OLDEMP(3) EMPST1 EMPST2 EMPST96;
 if year = 1996 then do;
  EMPST53 = EMPST96;
  EMPST42 = EMPST2;
  EMPST31 = EMPST1;
 end;

 if EMPST53 >= 0 then employ_last = EMPST53;
 else if EMPST42 >= 0 then employ_last = EMPST42;
 else if EMPST31 >= 0 then employ_last = EMPST31;
 else employ_last = .;

 employed = 1*(employ_last = 1) + 2*(employ_last > 1);
 if employed < 1 and AGELAST < 16 then employed = 9;
run;

proc format;
 value employed
 1 = "Employed"
 2 = "Not employed"
 9 = "Inapplicable (age < 16)"
 . = "Missing"
 0 = "Missing";
run;

/* Diabetes care: Hemoglobin A1c measurement */
data MEPS; set MEPS;
 if 0 < DSA1C53 & DSA1C53 < 96 then diab_a1c = 1;
 else diab_a1c = DSA1C53;
 if diab_a1c = 96 then diab_a1c = 0;

 if diabw05f>0 then domain=1;
 else do;
   domain=2;
   diabw05f=1;
 end;
run;

proc format;
 value diab_a1c
  1 = "Had measurement"
  0 = "Did not have measurement"
 -9 - -7 = "Don't know/Non-response"
 -1 = "Inapplicable";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
 FORMAT diab_a1c diab_a1c. employed employed.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT DIABW05F;
 TABLES domain*employed*diab_a1c / row;
run;

proc print data = out;
 where domain = 1 and diab_a1c ne . and employed ne .;
 var diab_a1c employed WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
