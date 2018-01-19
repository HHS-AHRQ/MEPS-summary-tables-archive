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

/* Reason for difficulty receiving needed prescribed medicines */
data MEPS; set MEPS;
 delay_PM  = (PMUNAB42=1|PMDLAY42=1);
 afford_PM = (PMDLRS42=1|PMUNRS42=1);
 insure_PM = (PMDLRS42 in (2,3)|PMUNRS42 in (2,3));
 other_PM  = (PMDLRS42 > 3|PMUNRS42 > 3);
 domain = (ACCELI42 = 1 & delay_PM=1);
run;

proc format;
 value afford 1 = "Couldn't afford";
 value insure 1 = "Insurance related";
 value other 1 = "Other";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
 FORMAT afford_PM afford. insure_PM insure. other_PM other. agegrps agegrps.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT02F;
 TABLES domain*agegrps*(afford_PM insure_PM other_PM) / row;
run;

proc print data = out;
 where domain = 1 and (afford_PM > 0 or insure_PM > 0 or other_PM > 0) and agegrps ne .;
 var afford_PM insure_PM other_PM agegrps WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
