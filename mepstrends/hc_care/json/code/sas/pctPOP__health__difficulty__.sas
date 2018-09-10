
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
  FORMAT delay: delay. health health.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  TABLES domain*health*(delay_ANY delay_MD delay_DN delay_PM) / row;
run;

proc print data = out;
  where domain = 1 and (delay_ANY > 0 or delay_MD > 0 or delay_DN > 0 or delay_PM > 0) and health ne .;
  var delay_ANY delay_MD delay_DN delay_PM health WgtFreq StdDev Frequency RowPercent RowStdErr;
run;

