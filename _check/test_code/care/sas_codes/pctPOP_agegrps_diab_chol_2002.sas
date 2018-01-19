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

/* Age groups */
/* To compute for all age groups, replace 'agegrps' in the SURVEY procedure with 'agegrps_v2X'  */
data MEPS; set MEPS;
 agegrps = AGELAST;
 agegrps_v2X = AGELAST;
 agegrps_v3X = AGELAST;
run;

proc format;
 value agegrps
 low-4 = "Under 5"
 5-17  = "5-17"
 18-44 = "18-44"
 45-64 = "45-64"
 65-high = "65+";

 value agegrps_v2X
 low-17  = "Under 18"
 18-64   = "18-64"
 65-high = "65+";

 value agegrps_v3X
 low-4 = "Under 5"
 5-6   = "5-6"
 7-12  = "7-12"
 13-17 = "13-17"
 18    = "18"
 19-24 = "19-24"
 25-29 = "25-29"
 30-34 = "30-34"
 35-44 = "35-44"
 45-54 = "45-54"
 55-64 = "55-64"
 65-high = "65+";
run;

/*  Diabetes care: Lipid profile */
data MEPS; set MEPS;
 ARRAY CHLVAR(5) CHOLCK53 DSCHNV53 DSCH0153 DSCH0253 DSCH0353;
 if year > 2007 then do;
  past_year = (DSCH0253=1 or DSCH0353=1);
  more_year = (DSCH0153=1 or DSCB0153=1);
  never_chk = (DSCHNV53 = 1);
  non_resp  = (DSCH0253 in (-7,-8,-9));
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

 if diabw02f>0 then domain=1;
 else do;
   domain=2;
   diabw02f=1;
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
 FORMAT diab_chol diab_chol. agegrps agegrps.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT DIABW02F;
 TABLES domain*agegrps*diab_chol / row;
run;

proc print data = out;
 where domain = 1 and diab_chol ne . and agegrps ne .;
 var diab_chol agegrps WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
