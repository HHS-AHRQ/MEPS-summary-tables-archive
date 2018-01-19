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

/* Sex */
proc format;
 value sex
 1 = "Male"
 2 = "Female";
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
 FORMAT afford_DN afford. insure_DN insure. other_DN other. sex sex.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT02F;
 TABLES domain*sex*(afford_DN insure_DN other_DN) / row;
run;

proc print data = out;
 where domain = 1 and (afford_DN > 0 or insure_DN > 0 or other_DN > 0) and sex ne .;
 var afford_DN insure_DN other_DN sex WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
