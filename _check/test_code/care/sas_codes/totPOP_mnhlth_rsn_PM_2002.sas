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

/* Perceived mental health */
data MEPS; set MEPS;
 ARRAY OLDMNH(2) MNTHLTH1 MNTHLTH2;
 if year = 1996 then do;
  MNHLTH53 = MNTHLTH2;
  MNHLTH42 = MNTHLTH2;
  MNHLTH31 = MNTHLTH1;
 end;

 if MNHLTH53 ge 0 then mnhlth = MNHLTH53;
 else if MNHLTH42 ge 0 then mnhlth = MNHLTH42;
 else if MNHLTH31 ge 0 then mnhlth = MNHLTH31;
 else mnhlth = .;
run;

proc format;
 value mnhlth
 1 = "Excellent"
 2 = "Very good"
 3 = "Good"
 4 = "Fair"
 5 = "Poor"
 . = "Missing";
run;

/* Reason for difficulty receiving needed prescribed medicines */
data MEPS; set MEPS;
 delay_PM  = (PMUNAB42=1|PMDLAY42=1);
 afford_PM = (PMDLRS42=1|PMUNRS42=1);
 insure_PM = (PMDLRS42 in (2,3)|PMUNRS42 in (2,3));
 other_PM  = (PMDLRS42 > 3|PMUNRS42 > 3);
 domain = (ACCELI42 = 1 & delay_PM=1);
run;

proc format;
 value afford 1 = "Couldn't afford";
 value insure 1 = "Insurance related";
 value other 1 = "Other";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
 FORMAT afford_PM afford. insure_PM insure. other_PM other. mnhlth mnhlth.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT02F;
 TABLES domain*mnhlth*(afford_PM insure_PM other_PM) / row;
run;

proc print data = out;
 where domain = 1 and (afford_PM > 0 or insure_PM > 0 or other_PM > 0) and mnhlth ne .;
 var afford_PM insure_PM other_PM mnhlth WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
