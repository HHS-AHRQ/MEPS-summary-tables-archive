
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

/* Education */
  data MEPS; set MEPS;
    ARRAY EDUVARS(4) EDUCYR&yy. EDUCYR EDUCYEAR EDRECODE;
    if year <= 1998 then EDUCYR = EDUCYR&yy.;
    else if year <= 2004 then EDUCYR = EDUCYEAR;

    if 2012 <= year < 2016 then do;
      less_than_hs = (0 <= EDRECODE and EDRECODE < 13);
      high_school  = (EDRECODE = 13);
      some_college = (EDRECODE > 13);
    end;

    else do;
      less_than_hs = (0 <= EDUCYR and EDUCYR < 12);
      high_school  = (EDUCYR = 12);
      some_college = (EDUCYR > 12);
    end;

    education = 1*less_than_hs + 2*high_school + 3*some_college;

    if AGELAST < 18 then education = 9;
  run;

  proc format;
    value education
    1 = "Less than high school"
    2 = "High school"
    3 = "Some college"
    9 = "Inapplicable (age < 18)"
    0 = "Missing"
    . = "Missing";
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

ods output Domain = out;
proc surveymeans data = MEPS sum missing nobs;
  FORMAT employed employed. education education.;
  VAR count;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  DOMAIN employed*education;
run;

proc print data = out;
run;

