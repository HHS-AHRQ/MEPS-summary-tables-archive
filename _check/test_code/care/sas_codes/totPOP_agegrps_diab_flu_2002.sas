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
 FORMAT diab_flu diab_flu. agegrps agegrps.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT DIABW02F;
 TABLES domain*agegrps*diab_flu / row;
run;

proc print data = out;
 where domain = 1 and diab_flu ne . and agegrps ne .;
 var diab_flu agegrps WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
