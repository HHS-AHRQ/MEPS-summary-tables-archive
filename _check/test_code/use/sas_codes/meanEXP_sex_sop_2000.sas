ods graphics off;

/* Read in dataset and initialize year */
FILENAME h50 "C:\MEPS\h50.ssp";
proc xcopy in = h50 out = WORK IMPORT;
run;

data MEPS;
 SET h50;
 ARRAY OLDVAR(5) VARPSU00 VARSTR00 WTDPER00 AGE2X AGE1X;
 year = 2000;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU00;
  VARSTR = VARSTR00;
 end;

 if year <= 1998 then do;
  PERWT00F = WTDPER00;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE00X >= 0 then AGELAST = AGE00x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Source of payment */
data MEPS; set MEPS;
 ARRAY OLDSOP(1) TOTCHM00;
 if year <= 1999 then do;
  TOTTRI00 = TOTCHM00;
 end;

 TOTOTH00 = TOTOFD00 + TOTSTL00 + TOTOPR00 + TOTOPU00 + TOTOSR00;
   TOTOTZ00 = TOTOTH00 + TOTWCP00 + TOTVA00;
   TOTPTR00 = TOTPRV00 + TOTTRI00;
run;

/* Sex */
proc format;
 value sex
 1 = "Male"
 2 = "Female";
run;

%let exp_vars = TOTEXP00 TOTSLF00 TOTPTR00 TOTMCR00 TOTMCD00 TOTOTZ00;

data MEPS_gt0; set MEPS;
 array vars &exp_vars.;
 do over vars;
  if vars <= 0 then vars = .;
 end;
run;

ods output Domain = out;
proc surveymeans data = MEPS_gt0 mean nobs nomcar;
 FORMAT sex sex.;
 VAR &exp_vars.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT00F;
 DOMAIN sex;
run;

proc print data = out;
run;
