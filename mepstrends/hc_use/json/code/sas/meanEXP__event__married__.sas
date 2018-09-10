
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

/* Marital Status */
  data MEPS; set MEPS;
    ARRAY OLDMAR(2) MARRY1X MARRY2X;
    if year = 1996 then do;
      if MARRY2X <= 6 then MARRY42X = MARRY2X;
      else MARRY42X = MARRY2X-6;

      if MARRY1X <= 6 then MARRY31X = MARRY1X;
      else MARRY31X = MARRY1X-6;
    end;

    if MARRY&yy.X >= 0 then married = MARRY&yy.X;
    else if MARRY42X >= 0 then married = MARRY42X;
    else if MARRY31X >= 0 then married = MARRY31X;
    else married = .;
  run;

  proc format;
    value married
    1 = "Married"
    2 = "Widowed"
    3 = "Divorced"
    4 = "Separated"
    5 = "Never married"
    6 = "Inapplicable (age < 16)"
    . = "Missing";
  run;

/* Event type */
  data MEPS; set MEPS;
    HHTEXP&yy. = HHAEXP&yy. + HHNEXP&yy.; /* Home Health Agency + Independent providers */
    ERTEXP&yy. = ERFEXP&yy. + ERDEXP&yy.; /* Doctor + Facility Expenses for OP, ER, IP events */
    IPTEXP&yy. = IPFEXP&yy. + IPDEXP&yy.;
    OPTEXP&yy. = OPFEXP&yy. + OPDEXP&yy.; /* All Outpatient */
    OPYEXP&yy. = OPVEXP&yy. + OPSEXP&yy.; /* Physician only */
    OPZEXP&yy. = OPOEXP&yy. + OPPEXP&yy.; /* non-physician only */
    OMAEXP&yy. = VISEXP&yy. + OTHEXP&yy.;

    TOTUSE&yy. =
      ((DVTOT&yy. > 0) + (RXTOT&yy. > 0) + (OBTOTV&yy. > 0) +
      (OPTOTV&yy. > 0) + (ERTOT&yy. > 0) + (IPDIS&yy. > 0) +
      (HHTOTD&yy. > 0) + (OMAEXP&yy. > 0));
  run;

%let exp_vars =
  TOTEXP&yy. DVTEXP&yy. RXEXP&yy.  OBVEXP&yy. OBDEXP&yy.
  OBOEXP&yy. OPTEXP&yy. OPYEXP&yy. OPZEXP&yy. ERTEXP&yy.
  IPTEXP&yy. HHTEXP&yy. OMAEXP&yy.;

data MEPS_gt0; set MEPS;
  array vars &exp_vars.;
  do over vars;
    if vars <= 0 then vars = .;
  end;
run;

ods output Domain = out;
proc surveymeans data = MEPS_gt0 mean nobs nomcar;
  FORMAT married married.;
  VAR &exp_vars.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  DOMAIN married;
run;

proc print data = out;
run;

