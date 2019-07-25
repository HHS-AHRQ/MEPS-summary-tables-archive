
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

%let exp_vars =
  TOTEXP&yy. DVTEXP&yy. RXEXP&yy.  OBVEXP&yy. OBDEXP&yy.
  OPTEXP&yy. OPYEXP&yy. ERTEXP&yy.
  IPTEXP&yy. HHTEXP&yy. OMAEXP&yy.;

ods output Domain = out;
proc surveymeans data = MEPS sum missing nobs;
  FORMAT agegrps agegrps.;
  VAR &exp_vars.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  DOMAIN agegrps;
run;

proc print data = out;
run;

