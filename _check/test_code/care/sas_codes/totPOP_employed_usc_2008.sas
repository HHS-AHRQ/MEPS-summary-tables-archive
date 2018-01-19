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

/* Usual source of care */
data MEPS; set MEPS;
 usc = LOCATN42;
 if HAVEUS42 = 2 then usc = 0;
 domain = (ACCELI42 = 1 & HAVEUS42 >= 0 & LOCATN42 >= -1);
run;

proc format;
 value usc
  0 = "No usual source of health care"
  1 = "Office-based"
  2 = "Hospital (not ER)"
  3 = "Emergency room"
 -1 = "Inapplicable"
 -8 = "Don't know";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
 FORMAT usc usc. employed employed.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT08F;
 TABLES domain*employed*usc / row;
run;

proc print data = out;
 where domain = 1 and usc ne . and employed ne .;
 var usc employed WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
