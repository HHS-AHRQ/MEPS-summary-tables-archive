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

/* Education */
data MEPS; set MEPS;
 ARRAY EDUVARS(4) EDUCYR02 EDUCYR EDUCYEAR EDRECODE;
 if year <= 1998 then EDUCYR = EDUCYR02;
 else if year <= 2004 then EDUCYR = EDUCYEAR;

 if year >= 2012 then do;
  less_than_hs = (0 <= EDRECODE and EDRECODE < 13);
  high_school  = (EDRECODE = 13);
  some_college = (EDRECODE > 13);
 end;

 else do;
  less_than_hs = (0 <= EDUCYR and EDUCYR < 12);
  high_school  = (EDUCYR = 12);
  some_college = (EDUCYR > 12);
 end;

 education = 1*less_than_hs + 2*high_school + 3*some_college;

 if AGELAST < 18 then education = 9;
run;

proc format;
 value education
 1 = "Less than high school"
 2 = "High school"
 3 = "Some college"
 9 = "Inapplicable (age < 18)"
 0 = "Missing"
 . = "Missing";
run;

/* Diabetes care: Eye exam */
data MEPS; set MEPS;

 past_year = (DSEY0253=1 | DSEY0353=1);
 more_year = (DSEY0153=1 | DSEB0153=1);
 never_chk = (DSEYNV53 = 1);
 non_resp = (DSEY0253 in (-7,-8,-9));

 if past_year = 1 then diab_eye = 1;
 else if more_year = 1 then diab_eye = 2;
 else if never_chk = 1 then diab_eye = 3;
 else if non_resp = 1  then diab_eye = -7;
 else diab_eye = -9;

 if diabw02f>0 then domain=1;
 else do;
   domain=2;
   diabw02f=1;
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
 FORMAT diab_eye diab_eye. education education.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT DIABW02F;
 TABLES domain*education*diab_eye / row;
run;

proc print data = out;
 where domain = 1 and diab_eye ne . and education ne .;
 var diab_eye education WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
