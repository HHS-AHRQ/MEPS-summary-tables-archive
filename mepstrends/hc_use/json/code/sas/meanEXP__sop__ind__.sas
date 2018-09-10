
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

data MEPS_gt0; set MEPS;
  array vars &exp_vars.;
  do over vars;
    if vars <= 0 then vars = .;
  end;
run;

ods output Domain = out;
proc surveymeans data = MEPS_gt0 mean nobs nomcar;
  FORMAT ind ind.;
  VAR &exp_vars.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  DOMAIN ind;
run;

proc print data = out;
run;

