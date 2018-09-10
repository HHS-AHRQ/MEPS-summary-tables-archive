
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

/* Marital Status */
  data MEPS; set MEPS;
    ARRAY OLDMAR(2) MARRY1X MARRY2X;
    if year = 1996 then do;
      if MARRY2X <= 6 then MARRY42X = MARRY2X;
      else MARRY42X = MARRY2X-6;

      if MARRY1X <= 6 then MARRY31X = MARRY1X;
      else MARRY31X = MARRY1X-6;
    end;

    if MARRY&yy.X >= 0 then married = MARRY&yy.X;
    else if MARRY42X >= 0 then married = MARRY42X;
    else if MARRY31X >= 0 then married = MARRY31X;
    else married = .;
  run;

  proc format;
    value married
    1 = "Married"
    2 = "Widowed"
    3 = "Divorced"
    4 = "Separated"
    5 = "Never married"
    6 = "Inapplicable (age < 16)"
    . = "Missing";
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
  FORMAT delay: delay. married married.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  TABLES domain*married*(delay_ANY delay_MD delay_DN delay_PM) / row;
run;

proc print data = out;
  where domain = 1 and (delay_ANY > 0 or delay_MD > 0 or delay_DN > 0 or delay_PM > 0) and married ne .;
  var delay_ANY delay_MD delay_DN delay_PM married WgtFreq StdDev Frequency RowPercent RowStdErr;
run;

