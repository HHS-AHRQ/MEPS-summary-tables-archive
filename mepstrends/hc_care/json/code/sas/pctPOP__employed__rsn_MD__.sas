
ods graphics off;

/* Read in dataset and initialize year */
  FILENAME &FYC. "C:\MEPS\&FYC..ssp";
  proc xcopy in = &FYC. out = WORK IMPORT;
  run;

  data MEPS;
    SET &FYC.;
    year = &year.;
    ind = 1;
    count = 1;

    /* Create AGELAST variable */
    if AGE&yy.X >= 0 then AGELAST=AGE&yy.x;
    else if AGE42X >= 0 then AGELAST=AGE42X;
    else if AGE31X >= 0 then AGELAST=AGE31X;
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

/* Reason for difficulty receiving needed medical care */
data MEPS; set MEPS;
  delay_MD  = (MDUNAB42=1|MDDLAY42=1);
  afford_MD = (MDDLRS42=1|MDUNRS42=1);
  insure_MD = (MDDLRS42 in (2,3)|MDUNRS42 in (2,3));
  other_MD  = (MDDLRS42 > 3|MDUNRS42 > 3);
  domain = (ACCELI42 = 1 & delay_MD=1);
run;

proc format;
  value afford 1 = "Couldn't afford";
  value insure 1 = "Insurance related";
  value other 1 = "Other";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
  FORMAT afford_MD afford. insure_MD insure. other_MD other. employed employed.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  TABLES domain*employed*(afford_MD insure_MD other_MD) / row;
run;

proc print data = out;
  where domain = 1 and (afford_MD > 0 or insure_MD > 0 or other_MD > 0) and employed ne .;
  var afford_MD insure_MD other_MD employed WgtFreq StdDev Frequency RowPercent RowStdErr;
run;

