
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

/* Difficulty receiving needed care */
data MEPS; set MEPS;
  delay_MD = (MDUNAB42 = 1|MDDLAY42=1);
  delay_DN = (DNUNAB42 = 1|DNDLAY42=1);
  delay_PM = (PMUNAB42 = 1|PMDLAY42=1);
  delay_ANY = (delay_MD|delay_DN|delay_PM);
  domain = (ACCELI42 = 1);
run;

proc format;
  value delay
  1 = "Difficulty accessing care"
  0 = "No difficulty";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
  FORMAT delay: delay. agegrps agegrps.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  TABLES domain*agegrps*(delay_ANY delay_MD delay_DN delay_PM) / row;
run;

proc print data = out;
  where domain = 1 and (delay_ANY > 0 or delay_MD > 0 or delay_DN > 0 or delay_PM > 0) and agegrps ne .;
  var delay_ANY delay_MD delay_DN delay_PM agegrps WgtFreq StdDev Frequency RowPercent RowStdErr;
run;

