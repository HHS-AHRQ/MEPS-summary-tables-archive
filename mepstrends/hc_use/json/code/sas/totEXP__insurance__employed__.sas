
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

/* Insurance coverage */
/* To compute for insurance categories, replace 'insurance' in the SURVEY procedure with 'insurance_v2X' */
  data MEPS; set MEPS;
    ARRAY OLDINS(4) MCDEVER MCREVER OPAEVER OPBEVER;
    if year = 1996 then do;
      MCDEV96 = MCDEVER;
      MCREV96 = MCREVER;
      OPAEV96 = OPAEVER;
      OPBEV96 = OPBEVER;
    end;

    if year < 2011 then do;
      public   = (MCDEV&yy. = 1) or (OPAEV&yy.=1) or (OPBEV&yy.=1);
      medicare = (MCREV&yy.=1);
      private  = (INSCOV&yy.=1);

      mcr_priv = (medicare and  private);
      mcr_pub  = (medicare and ~private and public);
      mcr_only = (medicare and ~private and ~public);
      no_mcr   = (~medicare);

      ins_gt65 = 4*mcr_only + 5*mcr_priv + 6*mcr_pub + 7*no_mcr;

      if AGELAST < 65 then INSURC&yy. = INSCOV&yy.;
      else INSURC&yy. = ins_gt65;
    end;

    insurance = INSCOV&yy.;
    insurance_v2X = INSURC&yy.;
  run;

  proc format;
    value insurance
    1 = "Any private, all ages"
    2 = "Public only, all ages"
    3 = "Uninsured, all ages";

    value insurance_v2X
    1 = "<65, Any private"
    2 = "<65, Public only"
    3 = "<65, Uninsured"
    4 = "65+, Medicare only"
    5 = "65+, Medicare and private"
    6 = "65+, Medicare and other public"
    7 = "65+, No medicare"
    8 = "65+, No medicare";
  run;

ods output Domain = out;
proc surveymeans data = MEPS sum missing nobs;
  FORMAT insurance insurance. employed employed.;
  VAR TOTEXP&yy.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  DOMAIN insurance*employed;
run;

proc print data = out;
run;

