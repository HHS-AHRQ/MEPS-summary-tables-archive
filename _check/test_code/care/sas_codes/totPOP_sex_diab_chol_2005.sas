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

/* Sex */
proc format;
 value sex
 1 = "Male"
 2 = "Female";
run;

/*  Diabetes care: Lipid profile */
data MEPS; set MEPS;
 ARRAY CHLVAR(5) CHOLCK53 DSCHNV53 DSCH0453 DSCH0553 DSCH0653;
 if year > 2007 then do;
  past_year = (DSCH0553=1 or DSCH0653=1);
  more_year = (DSCH0453=1 or DSCB0453=1);
  never_chk = (DSCHNV53 = 1);
  non_resp  = (DSCH0553 in (-7,-8,-9));
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

 if diabw05f>0 then domain=1;
 else do;
   domain=2;
   diabw05f=1;
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
 FORMAT diab_chol diab_chol. sex sex.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT DIABW05F;
 TABLES domain*sex*diab_chol / row;
run;

proc print data = out;
 where domain = 1 and diab_chol ne . and sex ne .;
 var diab_chol sex WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
