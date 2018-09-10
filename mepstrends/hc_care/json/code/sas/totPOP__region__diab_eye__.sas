
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

/* Diabetes care: Eye exam */
data MEPS; set MEPS;

  past_year = (DSEY&yy.53=1 | DSEY&ya.53=1);
  more_year = (DSEY&yb.53=1 | DSEB&yb.53=1);
  never_chk = (DSEYNV53 = 1);
  non_resp = (DSEY&yy.53 in (-7,-8,-9));

  if past_year = 1 then diab_eye = 1;
  else if more_year = 1 then diab_eye = 2;
  else if never_chk = 1 then diab_eye = 3;
  else if non_resp = 1  then diab_eye = -7;
  else diab_eye = -9;

  if diabw&yy.f>0 then domain=1;
  else do;
    domain=2;
    diabw&yy.f=1;
  end;
run;

proc format;
  value diab_eye
   1 = "In the past year"
   2 = "More than 1 year ago"
   3 = "Never had eye exam"
   4 = "No exam in past year"
  -1 = "Inapplicable"
  -7 = "Don't know/Non-response"
  -9 = "Missing";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
  FORMAT diab_eye diab_eye. region region.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT DIABW&yy.F;
  TABLES domain*region*diab_eye / row;
run;

proc print data = out;
  where domain = 1 and diab_eye ne . and region ne .;
  var diab_eye region WgtFreq StdDev Frequency RowPercent RowStdErr;
run;

