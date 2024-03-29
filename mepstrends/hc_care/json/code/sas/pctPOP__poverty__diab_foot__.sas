
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

/* Poverty status */
  data MEPS; set MEPS;
    ARRAY OLDPOV(1) POVCAT;
    if year = 1996 then POVCAT96 = POVCAT;
    poverty = POVCAT&yy.;
  run;

  proc format;
    value poverty
    1 = "Negative or poor"
    2 = "Near-poor"
    3 = "Low income"
    4 = "Middle income"
    5 = "High income";
  run;

/* Diabetes care: Foot care */
data MEPS; set MEPS;
  ARRAY FTVAR(5) DSCKFT53 DSFTNV53 DSFT&yb.53 DSFT&yy.53 DSFT&ya.53;
  if year > 2007 then do;
    past_year = (DSFT&yy.53=1 | DSFT&ya.53=1);
    more_year = (DSFT&yb.53=1 | DSFB&yb.53=1);
    never_chk = (DSFTNV53 = 1);
    non_resp  = (DSFT&yy.53 in (-7,-8,-9));
    inapp     = (DSFT&yy.53 = -1);
  end;

  else do;
    past_year = (DSCKFT53 >= 1);
    not_past_year = (DSCKFT53 = 0);
    non_resp  = (DSCKFT53 in (-7,-8,-9));
    inapp     = (DSCKFT53 = -1);
  end;

  if past_year = 1 then diab_foot = 1;
  else if more_year = 1 then diab_foot = 2;
  else if never_chk = 1 then diab_foot = 3;
  else if not_past_year = 1 then diab_foot = 4;
  else if inapp = 1     then diab_foot = -1;
  else if non_resp = 1  then diab_foot = -7;
  else diab_foot = -9;

  if diabw&yy.f>0 then domain=1;
  else do;
    domain=2;
    diabw&yy.f=1;
  end;
run;

proc format;
  value diab_foot
   1 = "In the past year"
   2 = "More than 1 year ago"
   3 = "Never had feet checked"
   4 = "No exam in past year"
  -1 = "Inapplicable"
  -7 = "Don't know/Non-response"
  -9 = "Missing";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
  FORMAT diab_foot diab_foot. poverty poverty.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT DIABW&yy.F;
  TABLES domain*poverty*diab_foot / row;
run;

proc print data = out;
  where domain = 1 and diab_foot ne . and poverty ne .;
  var diab_foot poverty WgtFreq StdDev Frequency RowPercent RowStdErr;
run;

