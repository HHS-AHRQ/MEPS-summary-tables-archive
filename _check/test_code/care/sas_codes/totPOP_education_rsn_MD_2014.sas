ods graphics off;

/* Read in dataset and initialize year */
FILENAME h171 "C:\MEPS\h171.ssp";
proc xcopy in = h171 out = WORK IMPORT;
run;

data MEPS;
 SET h171;
 year = 2014;
 ind = 1;
 count = 1;

 /* Create AGELAST variable */
 if AGE14X >= 0 then AGELAST=AGE14x;
 else if AGE42X >= 0 then AGELAST=AGE42X;
 else if AGE31X >= 0 then AGELAST=AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Education */
data MEPS; set MEPS;
 ARRAY EDUVARS(4) EDUCYR14 EDUCYR EDUCYEAR EDRECODE;
 if year <= 1998 then EDUCYR = EDUCYR14;
 else if year <= 2004 then EDUCYR = EDUCYEAR;

 if year >= 2012 then do;
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

/* Reason for difficulty receiving needed medical care */
data MEPS; set MEPS;
 delay_MD  = (MDUNAB42=1|MDDLAY42=1);
 afford_MD = (MDDLRS42=1|MDUNRS42=1);
 insure_MD = (MDDLRS42 in (2,3)|MDUNRS42 in (2,3));
 other_MD  = (MDDLRS42 > 3|MDUNRS42 > 3);
 domain = (ACCELI42 = 1 & delay_MD=1);
run;

proc format;
 value afford 1 = "Couldn't afford";
 value insure 1 = "Insurance related";
 value other 1 = "Other";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
 FORMAT afford_MD afford. insure_MD insure. other_MD other. education education.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT14F;
 TABLES domain*education*(afford_MD insure_MD other_MD) / row;
run;

proc print data = out;
 where domain = 1 and (afford_MD > 0 or insure_MD > 0 or other_MD > 0) and education ne .;
 var afford_MD insure_MD other_MD education WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
