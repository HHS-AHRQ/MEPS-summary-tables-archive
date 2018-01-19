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

/* Education */
data MEPS; set MEPS;
 ARRAY EDUVARS(4) EDUCYR12 EDUCYR EDUCYEAR EDRECODE;
 if year <= 1998 then EDUCYR = EDUCYR12;
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

/* How often doctor spent enough time (adults) */
data MEPS; set MEPS;
 adult_time = ADPRTM42;
 domain = (ADAPPT42 >= 1 & AGELAST >= 18);
 if domain = 0 and SAQWT12F = 0 then SAQWT12F = 1;
run;


proc format;
  value freq
   4 = "Always"
   3 = "Usually"
   2 = "Sometimes/Never"
   1 = "Sometimes/Never"
  -7 = "Don't know/Non-response"
  -8 = "Don't know/Non-response"
  -9 = "Don't know/Non-response"
  -1 = "Inapplicable"
  . = "Missing";
run;


ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
 FORMAT adult_time freq. education education.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT SAQWT12F;
 TABLES domain*education*adult_time / row;
run;

proc print data = out;
 where domain = 1 and adult_time ne . and education ne .;
 var adult_time education WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
