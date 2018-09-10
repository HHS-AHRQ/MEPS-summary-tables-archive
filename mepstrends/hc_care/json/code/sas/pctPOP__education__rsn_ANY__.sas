
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
  FORMAT afford_ANY afford. insure_ANY insure. other_ANY other. education education.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  TABLES domain*education*(afford_ANY insure_ANY other_ANY) / row;
run;

proc print data = out;
  where domain = 1 and (afford_ANY > 0 or insure_ANY > 0 or other_ANY > 0) and education ne .;
  var afford_ANY insure_ANY other_ANY education WgtFreq StdDev Frequency RowPercent RowStdErr;
run;

