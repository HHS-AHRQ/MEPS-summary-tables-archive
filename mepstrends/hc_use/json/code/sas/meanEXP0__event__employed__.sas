
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

/* Employment Status */
  data MEPS; set MEPS;
    ARRAY OLDEMP(3) EMPST1 EMPST2 EMPST96;
    if year = 1996 then do;
      EMPST53 = EMPST96;
      EMPST42 = EMPST2;
      EMPST31 = EMPST1;
    end;

    if EMPST53 >= 0 then employ_last = EMPST53;
    else if EMPST42 >= 0 then employ_last = EMPST42;
    else if EMPST31 >= 0 then employ_last = EMPST31;
    else employ_last = .;

    employed = 1*(employ_last = 1) + 2*(employ_last > 1);
    if employed < 1 and AGELAST < 16 then employed = 9;
  run;

  proc format;
    value employed
    1 = "Employed"
    2 = "Not employed"
    9 = "Inapplicable (age < 16)"
    . = "Missing"
    0 = "Missing";
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
proc surveymeans data = MEPS mean missing nobs;
  FORMAT employed employed.;
  VAR &exp_vars.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  DOMAIN employed;
run;

proc print data = out;
run;

