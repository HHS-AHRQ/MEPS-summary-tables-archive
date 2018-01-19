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
 FORMAT usc usc. agegrps agegrps.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT08F;
 TABLES domain*agegrps*usc / row;
run;

proc print data = out;
 where domain = 1 and usc ne . and agegrps ne .;
 var usc agegrps WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
