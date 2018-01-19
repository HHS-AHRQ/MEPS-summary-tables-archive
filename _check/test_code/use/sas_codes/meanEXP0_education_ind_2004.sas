ods graphics off;

/* Read in dataset and initialize year */
FILENAME h89 "C:\MEPS\h89.ssp";
proc xcopy in = h89 out = WORK IMPORT;
run;

data MEPS;
 SET h89;
 ARRAY OLDVAR(5) VARPSU04 VARSTR04 WTDPER04 AGE2X AGE1X;
 year = 2004;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU04;
  VARSTR = VARSTR04;
 end;

 if year <= 1998 then do;
  PERWT04F = WTDPER04;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE04X >= 0 then AGELAST = AGE04x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Education */
data MEPS; set MEPS;
 ARRAY EDUVARS(4) EDUCYR04 EDUCYR EDUCYEAR EDRECODE;
 if year <= 1998 then EDUCYR = EDUCYR04;
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

ods output Domain = out;
proc surveymeans data = MEPS mean missing nobs;
 FORMAT education education. ind ind.;
 VAR TOTEXP04;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT04F;
 DOMAIN education*ind;
run;

proc print data = out;
run;
