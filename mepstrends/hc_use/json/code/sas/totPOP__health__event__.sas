
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

/* Event type */
  data MEPS; set MEPS;
    HHTEXP&yy. = HHAEXP&yy. + HHNEXP&yy.; /* Home Health Agency + Independent providers */
    ERTEXP&yy. = ERFEXP&yy. + ERDEXP&yy.; /* Doctor + Facility Expenses for OP, ER, IP events */
    IPTEXP&yy. = IPFEXP&yy. + IPDEXP&yy.;
    OPTEXP&yy. = OPFEXP&yy. + OPDEXP&yy.; /* All Outpatient */
    OPYEXP&yy. = OPVEXP&yy. + OPSEXP&yy.; /* Outpatient - Physician only */
    OMAEXP&yy. = VISEXP&yy. + OTHEXP&yy.;

    TOTUSE&yy. =
      ((DVTOT&yy. > 0) + (RXTOT&yy. > 0) + (OBTOTV&yy. > 0) +
      (OPTOTV&yy. > 0) + (ERTOT&yy. > 0) + (IPDIS&yy. > 0) +
      (HHTOTD&yy. > 0) + (OMAEXP&yy. > 0));
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

%let use_vars =
  TOTUSE&yy. DVTOT&yy.  RXTOT&yy. OBTOTV&yy. OBDRV&yy.
  OPTOTV&yy. OPDRV&yy.  ERTOT&yy.
  IPDIS&yy.  HHTOTD&yy. OMAEXP&yy.;

data MEPS_use; set MEPS;
  array vars &use_vars.;
  do over vars;
    vars = (vars > 0);
  end;
run;

ods output Domain = out;
proc surveymeans data = MEPS_use sum missing nobs;
  FORMAT health health.;
  VAR &use_vars.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  DOMAIN health;
run;

proc print data = out;
run;

