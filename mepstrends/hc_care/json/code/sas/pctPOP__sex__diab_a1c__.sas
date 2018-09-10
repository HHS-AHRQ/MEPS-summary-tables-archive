
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

/* Sex */
  proc format;
    value sex
    1 = "Male"
    2 = "Female";
  run;

/* Diabetes care: Hemoglobin A1c measurement */
data MEPS; set MEPS;
  if 0 < DSA1C53 & DSA1C53 < 96 then diab_a1c = 1;
  else diab_a1c = DSA1C53;
  if diab_a1c = 96 then diab_a1c = 0;

  if diabw&yy.f>0 then domain=1;
  else do;
    domain=2;
    diabw&yy.f=1;
  end;
run;

proc format;
  value diab_a1c
   1 = "Had measurement"
   0 = "Did not have measurement"
  -9 - -7 = "Don't know/Non-response"
  -1 = "Inapplicable";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
  FORMAT diab_a1c diab_a1c. sex sex.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT DIABW&yy.F;
  TABLES domain*sex*diab_a1c / row;
run;

proc print data = out;
  where domain = 1 and diab_a1c ne . and sex ne .;
  var diab_a1c sex WgtFreq StdDev Frequency RowPercent RowStdErr;
run;

