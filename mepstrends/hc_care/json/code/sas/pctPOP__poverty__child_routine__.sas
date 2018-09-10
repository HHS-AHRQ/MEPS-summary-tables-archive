
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

/* Ability to schedule a routine appt. (children) */
data MEPS; set MEPS;
  child_routine = CHRTWW42;
  domain = (CHRTCR42 = 1 & AGELAST < 18);
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
  FORMAT child_routine freq. poverty poverty.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  TABLES domain*poverty*child_routine / row;
run;

proc print data = out;
  where domain = 1 and child_routine ne . and poverty ne .;
  var child_routine poverty WgtFreq StdDev Frequency RowPercent RowStdErr;
run;

