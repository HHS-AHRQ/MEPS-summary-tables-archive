
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

/* Perceived mental health */
  data MEPS; set MEPS;
    ARRAY OLDMNH(2) MNTHLTH1 MNTHLTH2;
    if year = 1996 then do;
      MNHLTH53 = MNTHLTH2;
      MNHLTH42 = MNTHLTH2;
      MNHLTH31 = MNTHLTH1;
    end;

    if MNHLTH53 ge 0 then mnhlth = MNHLTH53;
    else if MNHLTH42 ge 0 then mnhlth = MNHLTH42;
    else if MNHLTH31 ge 0 then mnhlth = MNHLTH31;
    else mnhlth = .;
  run;

  proc format;
    value mnhlth
    1 = "Excellent"
    2 = "Very good"
    3 = "Good"
    4 = "Fair"
    5 = "Poor"
    . = "Missing";
  run;

/* Source of payment */
  data MEPS; set MEPS;
    ARRAY OLDSOP(1) TOTCHM&yy.;
    if year <= 1999 then do;
      TOTTRI&yy. = TOTCHM&yy.;
    end;

    TOTOTH&yy. = TOTOFD&yy. + TOTSTL&yy. + TOTOPR&yy. + TOTOPU&yy. + TOTOSR&yy.;
      TOTOTZ&yy. = TOTOTH&yy. + TOTWCP&yy. + TOTVA&yy.;
      TOTPTR&yy. = TOTPRV&yy. + TOTTRI&yy.;
  run;

%let exp_vars = TOTEXP&yy. TOTSLF&yy. TOTPTR&yy. TOTMCR&yy. TOTMCD&yy. TOTOTZ&yy.;

ods output Domain = out;
proc surveymeans data = MEPS mean missing nobs;
  FORMAT mnhlth mnhlth.;
  VAR &exp_vars.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  DOMAIN mnhlth;
run;

proc print data = out;
run;

