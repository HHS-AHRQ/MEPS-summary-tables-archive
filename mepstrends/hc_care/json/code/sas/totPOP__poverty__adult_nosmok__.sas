
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

/* Adults advised to quit smoking */
data MEPS; set MEPS;
  ARRAY SMKVAR(2) ADDSMK42 ADNSMK42;
  if year <= 2002 then adult_nosmok = ADDSMK42;
  else adult_nosmok = ADNSMK42;

  domain = (ADSMOK42=1);
  if domain = 0 and SAQWT&yy.F = 0 then SAQWT&yy.F = 1;
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
  FORMAT adult_nosmok adult_nosmok. poverty poverty.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT SAQWT&yy.F;
  TABLES domain*poverty*adult_nosmok / row;
run;

proc print data = out;
  where domain = 1 and adult_nosmok ne . and poverty ne .;
  var adult_nosmok poverty WgtFreq StdDev Frequency RowPercent RowStdErr;
run;

