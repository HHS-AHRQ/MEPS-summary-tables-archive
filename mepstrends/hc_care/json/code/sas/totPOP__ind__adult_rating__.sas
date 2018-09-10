
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

/* Rating for care (adults) */
data MEPS; set MEPS;
  adult_rating = ADHECR42;
  domain = (ADAPPT42 >= 1 & AGELAST >= 18);
  if domain = 0 and SAQWT&yy.F = 0 then SAQWT&yy.F = 1;
run;

proc format;
  value adult_rating
  9-10 = "9-10 rating"
  7-8 = "7-8 rating"
  0-6 = "0-6 rating"
  -9 - -7 = "Don't know/Non-response"
  -1 = "Inapplicable";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
  FORMAT adult_rating adult_rating. ind ind.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT SAQWT&yy.F;
  TABLES domain*ind*adult_rating / row;
run;

proc print data = out;
  where domain = 1 and adult_rating ne . and ind ne .;
  var adult_rating ind WgtFreq StdDev Frequency RowPercent RowStdErr;
run;

