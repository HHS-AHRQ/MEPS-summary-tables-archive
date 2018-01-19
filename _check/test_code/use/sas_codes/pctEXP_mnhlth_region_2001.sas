ods graphics off;

/* Read in dataset and initialize year */
FILENAME h60 "C:\MEPS\h60.ssp";
proc xcopy in = h60 out = WORK IMPORT;
run;

data MEPS;
 SET h60;
 ARRAY OLDVAR(5) VARPSU01 VARSTR01 WTDPER01 AGE2X AGE1X;
 year = 2001;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU01;
  VARSTR = VARSTR01;
 end;

 if year <= 1998 then do;
  PERWT01F = WTDPER01;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE01X >= 0 then AGELAST = AGE01x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
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

 if REGION01 >= 0 then region = REGION01;
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

data MEPS_gt0; set MEPS;
  TOTEXP01 = (TOTEXP01 > 0);
run;

ods output Domain = out;
proc surveymeans data = MEPS_gt0 mean missing nobs;
 FORMAT mnhlth mnhlth. region region.;
 VAR TOTEXP01;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT01F;
 DOMAIN mnhlth*region;
run;

proc print data = out;
run;
