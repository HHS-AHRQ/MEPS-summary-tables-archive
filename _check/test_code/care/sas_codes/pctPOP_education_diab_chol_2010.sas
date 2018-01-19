ods graphics off;

/* Read in dataset and initialize year */
FILENAME h138 "C:\MEPS\h138.ssp";
proc xcopy in = h138 out = WORK IMPORT;
run;

data MEPS;
 SET h138;
 year = 2010;
 ind = 1;
 count = 1;

 /* Create AGELAST variable */
 if AGE10X >= 0 then AGELAST=AGE10x;
 else if AGE42X >= 0 then AGELAST=AGE42X;
 else if AGE31X >= 0 then AGELAST=AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Education */
data MEPS; set MEPS;
 ARRAY EDUVARS(4) EDUCYR10 EDUCYR EDUCYEAR EDRECODE;
 if year <= 1998 then EDUCYR = EDUCYR10;
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

/*  Diabetes care: Lipid profile */
data MEPS; set MEPS;
 ARRAY CHLVAR(5) CHOLCK53 DSCHNV53 DSCH0953 DSCH1053 DSCH1153;
 if year > 2007 then do;
  past_year = (DSCH1053=1 or DSCH1153=1);
  more_year = (DSCH0953=1 or DSCB0953=1);
  never_chk = (DSCHNV53 = 1);
  non_resp  = (DSCH1053 in (-7,-8,-9));
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

 if diabw10f>0 then domain=1;
 else do;
   domain=2;
   diabw10f=1;
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
 FORMAT diab_chol diab_chol. education education.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT DIABW10F;
 TABLES domain*education*diab_chol / row;
run;

proc print data = out;
 where domain = 1 and diab_chol ne . and education ne .;
 var diab_chol education WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
