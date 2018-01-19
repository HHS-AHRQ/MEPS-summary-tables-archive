ods graphics off;

/* Read in dataset and initialize year */
FILENAME h181 "C:\MEPS\h181.ssp";
proc xcopy in = h181 out = WORK IMPORT;
run;

data MEPS;
 SET h181;
 year = 2015;
 ind = 1;
 count = 1;

 /* Create AGELAST variable */
 if AGE15X >= 0 then AGELAST=AGE15x;
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

/* Reason for difficulty receiving needed dental care */
data MEPS; set MEPS;
 delay_DN  = (DNUNAB42=1|DNDLAY42=1);
 afford_DN = (DNDLRS42=1|DNUNRS42=1);
 insure_DN = (DNDLRS42 in (2,3)|DNUNRS42 in (2,3));
 other_DN  = (DNDLRS42 > 3|DNUNRS42 > 3);
 domain = (ACCELI42 = 1 & delay_DN=1);
run;

proc format;
 value afford 1 = "Couldn't afford";
 value insure 1 = "Insurance related";
 value other 1 = "Other";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
 FORMAT afford_DN afford. insure_DN insure. other_DN other. employed employed.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT15F;
 TABLES domain*employed*(afford_DN insure_DN other_DN) / row;
run;

proc print data = out;
 where domain = 1 and (afford_DN > 0 or insure_DN > 0 or other_DN > 0) and employed ne .;
 var afford_DN insure_DN other_DN employed WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
