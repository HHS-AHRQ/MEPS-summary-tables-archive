ods graphics off;

/* Read in dataset and initialize year */
FILENAME h155 "C:\MEPS\h155.ssp";
proc xcopy in = h155 out = WORK IMPORT;
run;

data MEPS;
 SET h155;
 year = 2012;
 ind = 1;
 count = 1;

 /* Create AGELAST variable */
 if AGE12X >= 0 then AGELAST=AGE12x;
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

/* Adults advised to quit smoking */
data MEPS; set MEPS;
 ARRAY SMKVAR(2) ADDSMK42 ADNSMK42;
 if year <= 2002 then adult_nosmok = ADDSMK42;
 else adult_nosmok = ADNSMK42;

 domain = (ADSMOK42=1 & CHECK53=1);
 if domain = 0 and SAQWT12F = 0 then SAQWT12F = 1;
run;

proc format;
 value adult_nosmok
  1 = "Told to quit"
  2 = "Not told to quit"
  3 = "Had no visits in the last 12 months"
 -9 = "Not ascertained"
 -1 = "Inapplicable";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
 FORMAT adult_nosmok adult_nosmok. agegrps agegrps.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT SAQWT12F;
 TABLES domain*agegrps*adult_nosmok / row;
run;

proc print data = out;
 where domain = 1 and adult_nosmok ne . and agegrps ne .;
 var adult_nosmok agegrps WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
