
ods graphics off;

/* Read in FYC dataset and initialize year */
  FILENAME &FYC. "C:\MEPS\&FYC..ssp";
  proc xcopy in = &FYC. out = WORK IMPORT;
  run;

  data MEPS;
    SET &FYC.;
    ARRAY OLDVAR(5) VARPSU&yy. VARSTR&yy. WTDPER&yy. AGE2X AGE1X;
    year = &year.;
    ind = 1;
    count = 1;

    if year <= 2001 then do;
      VARPSU = VARPSU&yy.;
      VARSTR = VARSTR&yy.;
    end;

    if year <= 1998 then do;
      PERWT&yy.F = WTDPER&yy.;
    end;

    /* Create AGELAST variable */
    if year = 1996 then do;
      AGE42X = AGE2X;
      AGE31X = AGE1X;
    end;

    if AGE&yy.X >= 0 then AGELAST = AGE&yy.x;
    else if AGE42X >= 0 then AGELAST = AGE42X;
    else if AGE31X >= 0 then AGELAST = AGE31X;
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

data MEPS_gt0; set MEPS;
  if TOTEXP&yy. <= 0 then TOTEXP&yy. = .;
run;

ods output Domain = out;
proc surveymeans data = MEPS_gt0 mean nobs nomcar;
  FORMAT region region. health health.;
  VAR TOTEXP&yy.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  DOMAIN region*health;
run;

proc print data = out;
run;

