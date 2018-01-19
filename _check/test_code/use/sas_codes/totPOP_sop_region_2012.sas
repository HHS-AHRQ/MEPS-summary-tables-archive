ods graphics off;

/* Read in dataset and initialize year */
FILENAME h155 "C:\MEPS\h155.ssp";
proc xcopy in = h155 out = WORK IMPORT;
run;

data MEPS;
 SET h155;
 ARRAY OLDVAR(5) VARPSU12 VARSTR12 WTDPER12 AGE2X AGE1X;
 year = 2012;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU12;
  VARSTR = VARSTR12;
 end;

 if year <= 1998 then do;
  PERWT12F = WTDPER12;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE12X >= 0 then AGELAST = AGE12x;
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

 if REGION12 >= 0 then region = REGION12;
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

/* Source of payment */
data MEPS; set MEPS;
 ARRAY OLDSOP(1) TOTCHM12;
 if year <= 1999 then do;
  TOTTRI12 = TOTCHM12;
 end;

 TOTOTH12 = TOTOFD12 + TOTSTL12 + TOTOPR12 + TOTOPU12 + TOTOSR12;
   TOTOTZ12 = TOTOTH12 + TOTWCP12 + TOTVA12;
   TOTPTR12 = TOTPRV12 + TOTTRI12;
run;

%let use_vars = TOTEXP12 TOTSLF12 TOTPTR12 TOTMCR12 TOTMCD12 TOTOTZ12;

data MEPS_use; set MEPS;
 array vars &use_vars.;
 do over vars;
  vars = (vars > 0);
 end;
run;

ods output Domain = out;
proc surveymeans data = MEPS_use sum missing nobs;
 FORMAT region region.;
 VAR &use_vars.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT12F;
 DOMAIN region;
run;

proc print data = out;
run;
