
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

/* Poverty status */
  data MEPS; set MEPS;
    ARRAY OLDPOV(1) POVCAT;
    if year = 1996 then POVCAT96 = POVCAT;
    poverty = POVCAT&yy.;
  run;

  proc format;
    value poverty
    1 = "Negative or poor"
    2 = "Near-poor"
    3 = "Low income"
    4 = "Middle income"
    5 = "High income";
  run;

/* How often doctor listened carefully (adults) */
data MEPS; set MEPS;
  adult_listen = ADLIST42;
  domain = (ADAPPT42 >= 1 & AGELAST >= 18);
  if domain = 0 and SAQWT&yy.F = 0 then SAQWT&yy.F = 1;
run;

proc format;
  value freq
   4 = "Always"
   3 = "Usually"
   2 = "Sometimes/Never"
   1 = "Sometimes/Never"
  -7 = "Don't know/Non-response"
  -8 = "Don't know/Non-response"
  -9 = "Don't know/Non-response"
  -1 = "Inapplicable"
  . = "Missing";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
  FORMAT adult_listen freq. poverty poverty.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT SAQWT&yy.F;
  TABLES domain*poverty*adult_listen / row;
run;

proc print data = out;
  where domain = 1 and adult_listen ne . and poverty ne .;
  var adult_listen poverty WgtFreq StdDev Frequency RowPercent RowStdErr;
run;

