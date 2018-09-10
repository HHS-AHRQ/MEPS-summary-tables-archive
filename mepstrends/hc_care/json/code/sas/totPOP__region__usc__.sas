
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

/* Census Region */
  data MEPS; set MEPS;
    ARRAY OLDREG(2) REGION1 REGION2;
    if year = 1996 then do;
      REGION42 = REGION2;
      REGION31 = REGION1;
    end;

    if REGION&yy. >= 0 then region = REGION&yy.;
    else if REGION42 >= 0 then region = REGION42;
    else if REGION31 >= 0 then region = REGION31;
    else region = .;
  run;

  proc format;
    value region
    1 = "Northeast"
    2 = "Midwest"
    3 = "South"
    4 = "West"
    . = "Missing";
  run;

/* Usual source of care */
data MEPS; set MEPS;
  usc = LOCATN42;
  if HAVEUS42 = 2 then usc = 0;
  domain = (ACCELI42 = 1 & HAVEUS42 >= 0 & LOCATN42 >= -1);
run;

proc format;
  value usc
   0 = "No usual source of health care"
   1 = "Office-based"
   2 = "Hospital (not ER)"
   3 = "Emergency room"
  -1 = "Inapplicable"
  -8 = "Don't know";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
  FORMAT usc usc. region region.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  TABLES domain*region*usc / row;
run;

proc print data = out;
  where domain = 1 and usc ne . and region ne .;
  var usc region WgtFreq StdDev Frequency RowPercent RowStdErr;
run;

