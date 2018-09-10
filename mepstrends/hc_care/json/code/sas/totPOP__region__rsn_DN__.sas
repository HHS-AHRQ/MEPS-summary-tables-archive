
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

/* Census Region */
  data MEPS; set MEPS;
    ARRAY OLDREG(2) REGION1 REGION2;
    if year = 1996 then do;
      REGION42 = REGION2;
      REGION31 = REGION1;
    end;

    if REGION&yy. >= 0 then region = REGION&yy.;
    else if REGION42 >= 0 then region = REGION42;
    else if REGION31 >= 0 then region = REGION31;
    else region = .;
  run;

  proc format;
    value region
    1 = "Northeast"
    2 = "Midwest"
    3 = "South"
    4 = "West"
    . = "Missing";
  run;

/* Reason for difficulty receiving needed dental care */
data MEPS; set MEPS;
  delay_DN  = (DNUNAB42=1|DNDLAY42=1);
  afford_DN = (DNDLRS42=1|DNUNRS42=1);
  insure_DN = (DNDLRS42 in (2,3)|DNUNRS42 in (2,3));
  other_DN  = (DNDLRS42 > 3|DNUNRS42 > 3);
  domain = (ACCELI42 = 1 & delay_DN=1);
run;

proc format;
  value afford 1 = "Couldn't afford";
  value insure 1 = "Insurance related";
  value other 1 = "Other";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
  FORMAT afford_DN afford. insure_DN insure. other_DN other. region region.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  TABLES domain*region*(afford_DN insure_DN other_DN) / row;
run;

proc print data = out;
  where domain = 1 and (afford_DN > 0 or insure_DN > 0 or other_DN > 0) and region ne .;
  var afford_DN insure_DN other_DN region WgtFreq StdDev Frequency RowPercent RowStdErr;
run;

