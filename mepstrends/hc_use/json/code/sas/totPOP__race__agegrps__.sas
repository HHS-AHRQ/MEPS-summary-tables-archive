
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

/* Age groups */
/* To compute for additional age groups, replace 'agegrps' in the SURVEY procedure with 'agegrps_v2X'  */
  data MEPS; set MEPS;
    agegrps = AGELAST;
    agegrps_v2X = AGELAST;
    agegrps_v3X = AGELAST;
  run;

  proc format;
    value agegrps
    low-4 = "Under 5"
    5-17  = "5-17"
    18-44 = "18-44"
    45-64 = "45-64"
    65-high = "65+";

    value agegrps_v2X
    low-17  = "Under 18"
    18-64   = "18-64"
    65-high = "65+";

    value agegrps_v3X
    low-4 = "Under 5"
    5-6   = "5-6"
    7-12  = "7-12"
    13-17 = "13-17"
    18    = "18"
    19-24 = "19-24"
    25-29 = "25-29"
    30-34 = "30-34"
    35-44 = "35-44"
    45-54 = "45-54"
    55-64 = "55-64"
    65-high = "65+";
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

ods output Domain = out;
proc surveymeans data = MEPS sum missing nobs;
  FORMAT race race. agegrps agegrps.;
  VAR count;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  DOMAIN race*agegrps;
run;

proc print data = out;
run;

