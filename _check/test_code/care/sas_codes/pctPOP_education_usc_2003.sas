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

/* Education */
data MEPS; set MEPS;
 ARRAY EDUVARS(4) EDUCYR03 EDUCYR EDUCYEAR EDRECODE;
 if year <= 1998 then EDUCYR = EDUCYR03;
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

/* Usual source of care */
data MEPS; set MEPS;
 usc = LOCATN42;
 if HAVEUS42 = 2 then usc = 0;
 domain = (ACCELI42 = 1 & HAVEUS42 >= 0 & LOCATN42 >= -1);
run;

proc format;
 value usc
  0 = "No usual source of health care"
  1 = "Office-based"
  2 = "Hospital (not ER)"
  3 = "Emergency room"
 -1 = "Inapplicable"
 -8 = "Don't know";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
 FORMAT usc usc. education education.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT03F;
 TABLES domain*education*usc / row;
run;

proc print data = out;
 where domain = 1 and usc ne . and education ne .;
 var usc education WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
