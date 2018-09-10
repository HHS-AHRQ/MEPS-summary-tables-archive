
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

/* Race/ethnicity */
  data MEPS; set MEPS;
    ARRAY RCEVAR(4) RACETHX RACEV1X RACETHNX RACEX;
    if year >= 2012 then do;
      hisp   = (RACETHX = 1);
      white  = (RACETHX = 2);
      black  = (RACETHX = 3);
      native = (RACETHX > 3 and RACEV1X in (3,6));
      asian  = (RACETHX > 3 and RACEV1X in (4,5));
      white_oth = 0;
    end;

    else if year >= 2002 then do;
      hisp   = (RACETHNX = 1);
      white  = (RACETHNX = 4 and RACEX = 1);
      black  = (RACETHNX = 2);
      native = (RACETHNX >= 3 and RACEX in (3,6));
      asian  = (RACETHNX >= 3 and RACEX in (4,5));
      white_oth = 0;
    end;

    else do;
      hisp  = (RACETHNX = 1);
      black = (RACETHNX = 2);
      white_oth = (RACETHNX = 3);
      white  = 0;
      native = 0;
      asian  = 0;
    end;

    race = 1*hisp + 2*white + 3*black + 4*native + 5*asian + 9*white_oth;
  run;

proc format;
  value race
  1 = "Hispanic"
  2 = "White"
  3 = "Black"
  4 = "Amer. Indian, AK Native, or mult. races"
  5 = "Asian, Hawaiian, or Pacific Islander"
  9 = "White and other"
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
  FORMAT afford_ANY afford. insure_ANY insure. other_ANY other. race race.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  TABLES domain*race*(afford_ANY insure_ANY other_ANY) / row;
run;

proc print data = out;
  where domain = 1 and (afford_ANY > 0 or insure_ANY > 0 or other_ANY > 0) and race ne .;
  var afford_ANY insure_ANY other_ANY race WgtFreq StdDev Frequency RowPercent RowStdErr;
run;

