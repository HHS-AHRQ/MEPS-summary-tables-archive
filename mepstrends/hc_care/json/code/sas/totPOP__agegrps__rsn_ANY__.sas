
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
  FORMAT afford_ANY afford. insure_ANY insure. other_ANY other. agegrps agegrps.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  TABLES domain*agegrps*(afford_ANY insure_ANY other_ANY) / row;
run;

proc print data = out;
  where domain = 1 and (afford_ANY > 0 or insure_ANY > 0 or other_ANY > 0) and agegrps ne .;
  var afford_ANY insure_ANY other_ANY agegrps WgtFreq StdDev Frequency RowPercent RowStdErr;
run;

