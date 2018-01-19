ods graphics off;

/* Read in dataset and initialize year */
FILENAME h79 "C:\MEPS\h79.ssp";
proc xcopy in = h79 out = WORK IMPORT;
run;

data MEPS;
 SET h79;
 year = 2003;
 ind = 1;
 count = 1;

 /* Create AGELAST variable */
 if AGE03X >= 0 then AGELAST=AGE03x;
 else if AGE42X >= 0 then AGELAST=AGE42X;
 else if AGE31X >= 0 then AGELAST=AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Adults advised to quit smoking */
data MEPS; set MEPS;
 ARRAY SMKVAR(2) ADDSMK42 ADNSMK42;
 if year <= 2002 then adult_nosmok = ADDSMK42;
 else adult_nosmok = ADNSMK42;

 domain = (ADSMOK42=1 & CHECK53=1);
 if domain = 0 and SAQWT03F = 0 then SAQWT03F = 1;
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
 FORMAT adult_nosmok adult_nosmok. ind ind.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT SAQWT03F;
 TABLES domain*ind*adult_nosmok / row;
run;

proc print data = out;
 where domain = 1 and adult_nosmok ne . and ind ne .;
 var adult_nosmok ind WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
