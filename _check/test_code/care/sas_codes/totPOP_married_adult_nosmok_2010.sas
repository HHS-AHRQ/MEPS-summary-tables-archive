ods graphics off;

/* Read in dataset and initialize year */
FILENAME h138 "C:\MEPS\h138.ssp";
proc xcopy in = h138 out = WORK IMPORT;
run;

data MEPS;
 SET h138;
 year = 2010;
 ind = 1;
 count = 1;

 /* Create AGELAST variable */
 if AGE10X >= 0 then AGELAST=AGE10x;
 else if AGE42X >= 0 then AGELAST=AGE42X;
 else if AGE31X >= 0 then AGELAST=AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Marital Status */
data MEPS; set MEPS;
 ARRAY OLDMAR(2) MARRY1X MARRY2X;
 if year = 1996 then do;
  if MARRY2X <= 6 then MARRY42X = MARRY2X;
  else MARRY42X = MARRY2X-6;

  if MARRY1X <= 6 then MARRY31X = MARRY1X;
  else MARRY31X = MARRY1X-6;
 end;

 if MARRY10X >= 0 then married = MARRY10X;
 else if MARRY42X >= 0 then married = MARRY42X;
 else if MARRY31X >= 0 then married = MARRY31X;
 else married = .;
run;

proc format;
 value married
 1 = "Married"
 2 = "Widowed"
 3 = "Divorced"
 4 = "Separated"
 5 = "Never married"
 6 = "Inapplicable (age < 16)"
 . = "Missing";
run;

/* Adults advised to quit smoking */
data MEPS; set MEPS;
 ARRAY SMKVAR(2) ADDSMK42 ADNSMK42;
 if year <= 2002 then adult_nosmok = ADDSMK42;
 else adult_nosmok = ADNSMK42;

 domain = (ADSMOK42=1 & CHECK53=1);
 if domain = 0 and SAQWT10F = 0 then SAQWT10F = 1;
run;

proc format;
 value adult_nosmok
  1 = "Told to quit"
  2 = "Not told to quit"
  3 = "Had no visits in the last 12 months"
 -9 = "Not ascertained"
 -1 = "Inapplicable";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
 FORMAT adult_nosmok adult_nosmok. married married.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT SAQWT10F;
 TABLES domain*married*adult_nosmok / row;
run;

proc print data = out;
 where domain = 1 and adult_nosmok ne . and married ne .;
 var adult_nosmok married WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
