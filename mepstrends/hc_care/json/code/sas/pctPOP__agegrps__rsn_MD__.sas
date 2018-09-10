
ods graphics off;

/* Read in dataset and initialize year */
  FILENAME &FYC. "C:\MEPS\&FYC..ssp";
  proc xcopy in = &FYC. out = WORK IMPORT;
  run;

  data MEPS;
    SET &FYC.;
    year = &year.;
    ind = 1;
    count = 1;

    /* Create AGELAST variable */
    if AGE&yy.X >= 0 then AGELAST=AGE&yy.x;
    else if AGE42X >= 0 then AGELAST=AGE42X;
    else if AGE31X >= 0 then AGELAST=AGE31X;
  run;

  proc format;
    value ind 1 = "Total";
  run;

/* Age groups */
/* To compute for additional age groups, replace 'agegrps' in the SURVEY procedure with 'agegrps_v2X'  */
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

/* Reason for difficulty receiving needed medical care */
data MEPS; set MEPS;
  delay_MD  = (MDUNAB42=1|MDDLAY42=1);
  afford_MD = (MDDLRS42=1|MDUNRS42=1);
  insure_MD = (MDDLRS42 in (2,3)|MDUNRS42 in (2,3));
  other_MD  = (MDDLRS42 > 3|MDUNRS42 > 3);
  domain = (ACCELI42 = 1 & delay_MD=1);
run;

proc format;
  value afford 1 = "Couldn't afford";
  value insure 1 = "Insurance related";
  value other 1 = "Other";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
  FORMAT afford_MD afford. insure_MD insure. other_MD other. agegrps agegrps.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  TABLES domain*agegrps*(afford_MD insure_MD other_MD) / row;
run;

proc print data = out;
  where domain = 1 and (afford_MD > 0 or insure_MD > 0 or other_MD > 0) and agegrps ne .;
  var afford_MD insure_MD other_MD agegrps WgtFreq StdDev Frequency RowPercent RowStdErr;
run;

