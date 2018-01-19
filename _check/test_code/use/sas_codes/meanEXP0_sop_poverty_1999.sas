ods graphics off;

/* Read in dataset and initialize year */
FILENAME h38 "C:\MEPS\h38.ssp";
proc xcopy in = h38 out = WORK IMPORT;
run;

data MEPS;
 SET h38;
 ARRAY OLDVAR(5) VARPSU99 VARSTR99 WTDPER99 AGE2X AGE1X;
 year = 1999;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU99;
  VARSTR = VARSTR99;
 end;

 if year <= 1998 then do;
  PERWT99F = WTDPER99;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE99X >= 0 then AGELAST = AGE99x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Poverty status */
data MEPS; set MEPS;
 ARRAY OLDPOV(1) POVCAT;
 if year = 1996 then POVCAT96 = POVCAT;
 poverty = POVCAT99;
run;

proc format;
 value poverty
 1 = "Negative or poor"
 2 = "Near-poor"
 3 = "Low income"
 4 = "Middle income"
 5 = "High income";
run;

/* Source of payment */
data MEPS; set MEPS;
 ARRAY OLDSOP(1) TOTCHM99;
 if year <= 1999 then do;
  TOTTRI99 = TOTCHM99;
 end;

 TOTOTH99 = TOTOFD99 + TOTSTL99 + TOTOPR99 + TOTOPU99 + TOTOSR99;
   TOTOTZ99 = TOTOTH99 + TOTWCP99 + TOTVA99;
   TOTPTR99 = TOTPRV99 + TOTTRI99;
run;

%let exp_vars = TOTEXP99 TOTSLF99 TOTPTR99 TOTMCR99 TOTMCD99 TOTOTZ99;

ods output Domain = out;
proc surveymeans data = MEPS mean missing nobs;
 FORMAT poverty poverty.;
 VAR &exp_vars.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT99F;
 DOMAIN poverty;
run;

proc print data = out;
run;
