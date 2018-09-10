
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

/* Perceived health status */
  data MEPS; set MEPS;
    ARRAY OLDHLT(2) RTEHLTH1 RTEHLTH2;
    if year = 1996 then do;
      RTHLTH53 = RTEHLTH2;
      RTHLTH42 = RTEHLTH2;
      RTHLTH31 = RTEHLTH1;
    end;

    if RTHLTH53 >= 0 then health = RTHLTH53;
    else if RTHLTH42 >= 0 then health = RTHLTH42;
    else if RTHLTH31 >= 0 then health = RTHLTH31;
    else health = .;
  run;

  proc format;
    value health
    1 = "Excellent"
    2 = "Very good"
    3 = "Good"
    4 = "Fair"
    5 = "Poor"
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
  FORMAT usc usc. health health.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  TABLES domain*health*usc / row;
run;

proc print data = out;
  where domain = 1 and usc ne . and health ne .;
  var usc health WgtFreq StdDev Frequency RowPercent RowStdErr;
run;

