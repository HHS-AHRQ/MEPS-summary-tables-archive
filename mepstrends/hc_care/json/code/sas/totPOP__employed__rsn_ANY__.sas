
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

/* Reason for difficulty receiving needed care */
data MEPS; set MEPS;
  delay_MD  = (MDUNAB42=1|MDDLAY42=1);
  delay_DN  = (DNUNAB42=1|DNDLAY42=1);
  delay_PM  = (PMUNAB42=1|PMDLAY42=1);

  afford_MD = (MDDLRS42=1|MDUNRS42=1);
  afford_DN = (DNDLRS42=1|DNUNRS42=1);
  afford_PM = (PMDLRS42=1|PMUNRS42=1);

  insure_MD = (MDDLRS42 in (2,3)|MDUNRS42 in (2,3));
  insure_DN = (DNDLRS42 in (2,3)|DNUNRS42 in (2,3));
  insure_PM = (PMDLRS42 in (2,3)|PMUNRS42 in (2,3));

  other_MD  = (MDDLRS42 > 3|MDUNRS42 > 3);
  other_DN  = (DNDLRS42 > 3|DNUNRS42 > 3);
  other_PM  = (PMDLRS42 > 3|PMUNRS42 > 3);

  delay_ANY  = (delay_MD |delay_DN |delay_PM);
  afford_ANY = (afford_MD|afford_DN|afford_PM);
  insure_ANY = (insure_MD|insure_DN|insure_PM);
  other_ANY  = (other_MD |other_DN |other_PM);

  domain = (ACCELI42 = 1 & delay_ANY=1);
run;

proc format;
  value afford 1 = "Couldn't afford";
  value insure 1 = "Insurance related";
  value other 1 = "Other";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
  FORMAT afford_ANY afford. insure_ANY insure. other_ANY other. employed employed.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  TABLES domain*employed*(afford_ANY insure_ANY other_ANY) / row;
run;

proc print data = out;
  where domain = 1 and (afford_ANY > 0 or insure_ANY > 0 or other_ANY > 0) and employed ne .;
  var afford_ANY insure_ANY other_ANY employed WgtFreq StdDev Frequency RowPercent RowStdErr;
run;

