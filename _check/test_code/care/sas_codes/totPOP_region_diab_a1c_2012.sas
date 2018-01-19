ods graphics off;

/* Read in dataset and initialize year */
FILENAME h155 "C:\MEPS\h155.ssp";
proc xcopy in = h155 out = WORK IMPORT;
run;

data MEPS;
 SET h155;
 year = 2012;
 ind = 1;
 count = 1;

 /* Create AGELAST variable */
 if AGE12X >= 0 then AGELAST=AGE12x;
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

 if REGION12 >= 0 then region = REGION12;
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

/* Diabetes care: Hemoglobin A1c measurement */
data MEPS; set MEPS;
 if 0 < DSA1C53 & DSA1C53 < 96 then diab_a1c = 1;
 else diab_a1c = DSA1C53;
 if diab_a1c = 96 then diab_a1c = 0;

 if diabw12f>0 then domain=1;
 else do;
   domain=2;
   diabw12f=1;
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
 FORMAT diab_a1c diab_a1c. region region.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT DIABW12F;
 TABLES domain*region*diab_a1c / row;
run;

proc print data = out;
 where domain = 1 and diab_a1c ne . and region ne .;
 var diab_a1c region WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
