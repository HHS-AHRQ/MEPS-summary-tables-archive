
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

/* Ability to schedule appt. for illness or injury (adults) */
data MEPS; set MEPS;
  adult_illness = ADILWW42;
  domain = (ADILCR42=1 & AGELAST >= 18);
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
  FORMAT adult_illness freq. ind ind.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT SAQWT&yy.F;
  TABLES domain*ind*adult_illness / row;
run;

proc print data = out;
  where domain = 1 and adult_illness ne . and ind ne .;
  var adult_illness ind WgtFreq StdDev Frequency RowPercent RowStdErr;
run;

