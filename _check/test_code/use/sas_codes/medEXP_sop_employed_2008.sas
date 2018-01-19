ods graphics off;

/* Read in dataset and initialize year */
FILENAME h121 "C:\MEPS\h121.ssp";
proc xcopy in = h121 out = WORK IMPORT;
run;

data MEPS;
 SET h121;
 ARRAY OLDVAR(5) VARPSU08 VARSTR08 WTDPER08 AGE2X AGE1X;
 year = 2008;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU08;
  VARSTR = VARSTR08;
 end;

 if year <= 1998 then do;
  PERWT08F = WTDPER08;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE08X >= 0 then AGELAST = AGE08x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Employment Status */
data MEPS; set MEPS;
 ARRAY OLDEMP(3) EMPST1 EMPST2 EMPST96;
 if year = 1996 then do;
  EMPST53 = EMPST96;
  EMPST42 = EMPST2;
  EMPST31 = EMPST1;
 end;

 if EMPST53 >= 0 then employ_last = EMPST53;
 else if EMPST42 >= 0 then employ_last = EMPST42;
 else if EMPST31 >= 0 then employ_last = EMPST31;
 else employ_last = .;

 employed = 1*(employ_last = 1) + 2*(employ_last > 1);
 if employed < 1 and AGELAST < 16 then employed = 9;
run;

proc format;
 value employed
 1 = "Employed"
 2 = "Not employed"
 9 = "Inapplicable (age < 16)"
 . = "Missing"
 0 = "Missing";
run;

/* Source of payment */
data MEPS; set MEPS;
 ARRAY OLDSOP(1) TOTCHM08;
 if year <= 1999 then do;
  TOTTRI08 = TOTCHM08;
 end;

 TOTOTH08 = TOTOFD08 + TOTSTL08 + TOTOPR08 + TOTOPU08 + TOTOSR08;
   TOTOTZ08 = TOTOTH08 + TOTWCP08 + TOTVA08;
   TOTPTR08 = TOTPRV08 + TOTTRI08;
run;

%let exp_vars = TOTEXP08 TOTSLF08 TOTPTR08 TOTMCR08 TOTMCD08 TOTOTZ08;

data MEPS_gt0; set MEPS;
 array vars &exp_vars.;
 do over vars;
  if vars <= 0 then vars = .;
 end;
run;

ods output DomainQuantiles = out;
proc surveymeans data = MEPS_gt0 median nobs nomcar;
 FORMAT employed employed.;
 VAR &exp_vars.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT08F;
 DOMAIN employed;
run;

proc print data = out;
run;
