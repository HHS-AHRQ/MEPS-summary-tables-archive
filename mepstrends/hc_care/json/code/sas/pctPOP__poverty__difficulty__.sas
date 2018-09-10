
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
  FORMAT delay: delay. poverty poverty.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  TABLES domain*poverty*(delay_ANY delay_MD delay_DN delay_PM) / row;
run;

proc print data = out;
  where domain = 1 and (delay_ANY > 0 or delay_MD > 0 or delay_DN > 0 or delay_PM > 0) and poverty ne .;
  var delay_ANY delay_MD delay_DN delay_PM poverty WgtFreq StdDev Frequency RowPercent RowStdErr;
run;

