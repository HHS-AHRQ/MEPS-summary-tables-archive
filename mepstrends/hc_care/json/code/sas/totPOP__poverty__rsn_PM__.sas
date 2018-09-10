
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
  FORMAT afford_PM afford. insure_PM insure. other_PM other. poverty poverty.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  TABLES domain*poverty*(afford_PM insure_PM other_PM) / row;
run;

proc print data = out;
  where domain = 1 and (afford_PM > 0 or insure_PM > 0 or other_PM > 0) and poverty ne .;
  var afford_PM insure_PM other_PM poverty WgtFreq StdDev Frequency RowPercent RowStdErr;
run;

