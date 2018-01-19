ods graphics off;

/* Read in dataset and initialize year */
FILENAME h12 "C:\MEPS\h12.ssp";
proc xcopy in = h12 out = WORK IMPORT;
run;

data MEPS;
 SET h12;
 ARRAY OLDVAR(5) VARPSU96 VARSTR96 WTDPER96 AGE2X AGE1X;
 year = 1996;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU96;
  VARSTR = VARSTR96;
 end;

 if year <= 1998 then do;
  PERWT96F = WTDPER96;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE96X >= 0 then AGELAST = AGE96x;
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

data MEPS_gt0; set MEPS;
 if TOTEXP96 <= 0 then TOTEXP96 = .;
run;

ods output DomainQuantiles = out;
proc surveymeans data = MEPS_gt0 median nobs nomcar;
 FORMAT ind ind. health health.;
 VAR TOTEXP96;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT96F;
 DOMAIN ind*health;
run;

proc print data = out;
run;
