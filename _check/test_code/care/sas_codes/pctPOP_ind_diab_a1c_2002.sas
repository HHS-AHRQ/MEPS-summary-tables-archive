ods graphics off;

/* Read in dataset and initialize year */
FILENAME h70 "C:\MEPS\h70.ssp";
proc xcopy in = h70 out = WORK IMPORT;
run;

data MEPS;
 SET h70;
 year = 2002;
 ind = 1;
 count = 1;

 /* Create AGELAST variable */
 if AGE02X >= 0 then AGELAST=AGE02x;
 else if AGE42X >= 0 then AGELAST=AGE42X;
 else if AGE31X >= 0 then AGELAST=AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Diabetes care: Hemoglobin A1c measurement */
data MEPS; set MEPS;
 if 0 < DSA1C53 & DSA1C53 < 96 then diab_a1c = 1;
 else diab_a1c = DSA1C53;
 if diab_a1c = 96 then diab_a1c = 0;

 if diabw02f>0 then domain=1;
 else do;
   domain=2;
   diabw02f=1;
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
 FORMAT diab_a1c diab_a1c. ind ind.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT DIABW02F;
 TABLES domain*ind*diab_a1c / row;
run;

proc print data = out;
 where domain = 1 and diab_a1c ne . and ind ne .;
 var diab_a1c ind WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
