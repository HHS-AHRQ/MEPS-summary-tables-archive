ods graphics off;

/* Read in dataset and initialize year */
FILENAME h163 "C:\MEPS\h163.ssp";
proc xcopy in = h163 out = WORK IMPORT;
run;

data MEPS;
 SET h163;
 ARRAY OLDVAR(5) VARPSU13 VARSTR13 WTDPER13 AGE2X AGE1X;
 year = 2013;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU13;
  VARSTR = VARSTR13;
 end;

 if year <= 1998 then do;
  PERWT13F = WTDPER13;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE13X >= 0 then AGELAST = AGE13x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Source of payment */
data MEPS; set MEPS;
 ARRAY OLDSOP(1) TOTCHM13;
 if year <= 1999 then do;
  TOTTRI13 = TOTCHM13;
 end;

 TOTOTH13 = TOTOFD13 + TOTSTL13 + TOTOPR13 + TOTOPU13 + TOTOSR13;
   TOTOTZ13 = TOTOTH13 + TOTWCP13 + TOTVA13;
   TOTPTR13 = TOTPRV13 + TOTTRI13;
run;

/* Age groups */
/* To compute for all age groups, replace 'agegrps' in the SURVEY procedure with 'agegrps_v2X'  */
data MEPS; set MEPS;
 agegrps = AGELAST;
 agegrps_v2X = AGELAST;
 agegrps_v3X = AGELAST;
run;

proc format;
 value agegrps
 low-4 = "Under 5"
 5-17  = "5-17"
 18-44 = "18-44"
 45-64 = "45-64"
 65-high = "65+";

 value agegrps_v2X
 low-17  = "Under 18"
 18-64   = "18-64"
 65-high = "65+";

 value agegrps_v3X
 low-4 = "Under 5"
 5-6   = "5-6"
 7-12  = "7-12"
 13-17 = "13-17"
 18    = "18"
 19-24 = "19-24"
 25-29 = "25-29"
 30-34 = "30-34"
 35-44 = "35-44"
 45-54 = "45-54"
 55-64 = "55-64"
 65-high = "65+";
run;

%let exp_vars = TOTEXP13 TOTSLF13 TOTPTR13 TOTMCR13 TOTMCD13 TOTOTZ13;

data MEPS_gt0; set MEPS;
 array vars &exp_vars.;
 do over vars;
  vars = (vars > 0);
 end;
run;

ods output Domain = out;
proc surveymeans data = MEPS_gt0 mean missing nobs;
 FORMAT agegrps agegrps.;
 VAR &exp_vars.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT13F;
 DOMAIN agegrps;
run;

proc print data = out;
run;
