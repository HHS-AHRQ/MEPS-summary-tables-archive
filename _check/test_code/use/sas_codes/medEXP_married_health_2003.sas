ods graphics off;

/* Read in dataset and initialize year */
FILENAME h79 "C:\MEPS\h79.ssp";
proc xcopy in = h79 out = WORK IMPORT;
run;

data MEPS;
 SET h79;
 ARRAY OLDVAR(5) VARPSU03 VARSTR03 WTDPER03 AGE2X AGE1X;
 year = 2003;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU03;
  VARSTR = VARSTR03;
 end;

 if year <= 1998 then do;
  PERWT03F = WTDPER03;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE03X >= 0 then AGELAST = AGE03x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Perceived health status */
data MEPS; set MEPS;
 ARRAY OLDHLT(2) RTEHLTH1 RTEHLTH2;
 if year = 1996 then do;
  RTHLTH53 = RTEHLTH2;
  RTHLTH42 = RTEHLTH2;
  RTHLTH31 = RTEHLTH1;
 end;

 if RTHLTH53 >= 0 then health = RTHLTH53;
 else if RTHLTH42 >= 0 then health = RTHLTH42;
 else if RTHLTH31 >= 0 then health = RTHLTH31;
 else health = .;
run;

proc format;
 value health
 1 = "Excellent"
 2 = "Very good"
 3 = "Good"
 4 = "Fair"
 5 = "Poor"
 . = "Missing";
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

 if MARRY03X >= 0 then married = MARRY03X;
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

data MEPS_gt0; set MEPS;
 if TOTEXP03 <= 0 then TOTEXP03 = .;
run;

ods output DomainQuantiles = out;
proc surveymeans data = MEPS_gt0 median nobs nomcar;
 FORMAT married married. health health.;
 VAR TOTEXP03;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT03F;
 DOMAIN married*health;
run;

proc print data = out;
run;
