
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

/* Race/ethnicity */
  data MEPS; set MEPS;
    ARRAY RCEVAR(4) RACETHX RACEV1X RACETHNX RACEX;
    if year >= 2012 then do;
      hisp   = (RACETHX = 1);
      white  = (RACETHX = 2);
      black  = (RACETHX = 3);
      native = (RACETHX > 3 and RACEV1X in (3,6));
      asian  = (RACETHX > 3 and RACEV1X in (4,5));
      white_oth = 0;
    end;

    else if year >= 2002 then do;
      hisp   = (RACETHNX = 1);
      white  = (RACETHNX = 4 and RACEX = 1);
      black  = (RACETHNX = 2);
      native = (RACETHNX >= 3 and RACEX in (3,6));
      asian  = (RACETHNX >= 3 and RACEX in (4,5));
      white_oth = 0;
    end;

    else do;
      hisp  = (RACETHNX = 1);
      black = (RACETHNX = 2);
      white_oth = (RACETHNX = 3);
      white  = 0;
      native = 0;
      asian  = 0;
    end;

    race = 1*hisp + 2*white + 3*black + 4*native + 5*asian + 9*white_oth;
  run;

proc format;
  value race
  1 = "Hispanic"
  2 = "White"
  3 = "Black"
  4 = "Amer. Indian, AK Native, or mult. races"
  5 = "Asian, Hawaiian, or Pacific Islander"
  9 = "White and other"
  . = "Missing";
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

ods output Domain = out;
proc surveymeans data = MEPS sum missing nobs;
  FORMAT health health. race race.;
  VAR TOTEXP&yy.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  DOMAIN health*race;
run;

proc print data = out;
run;

