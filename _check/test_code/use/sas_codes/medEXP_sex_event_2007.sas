ods graphics off;

/* Read in dataset and initialize year */
FILENAME h113 "C:\MEPS\h113.ssp";
proc xcopy in = h113 out = WORK IMPORT;
run;

data MEPS;
 SET h113;
 ARRAY OLDVAR(5) VARPSU07 VARSTR07 WTDPER07 AGE2X AGE1X;
 year = 2007;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU07;
  VARSTR = VARSTR07;
 end;

 if year <= 1998 then do;
  PERWT07F = WTDPER07;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE07X >= 0 then AGELAST = AGE07x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Event type */
data MEPS; set MEPS;
 HHTEXP07 = HHAEXP07 + HHNEXP07; /* Home Health Agency + Independent providers */
 ERTEXP07 = ERFEXP07 + ERDEXP07; /* Doctor + Facility Expenses for OP, ER, IP events */
 IPTEXP07 = IPFEXP07 + IPDEXP07;
 OPTEXP07 = OPFEXP07 + OPDEXP07; /* All Outpatient */
 OPYEXP07 = OPVEXP07 + OPSEXP07; /* Physician only */
 OPZEXP07 = OPOEXP07 + OPPEXP07; /* non-physician only */
 OMAEXP07 = VISEXP07 + OTHEXP07;

 TOTUSE07 = 
  ((DVTOT07 > 0) + (RXTOT07 > 0) + (OBTOTV07 > 0) +
  (OPTOTV07 > 0) + (ERTOT07 > 0) + (IPDIS07 > 0) +
  (HHTOTD07 > 0) + (OMAEXP07 > 0));
run;

/* Sex */
proc format;
 value sex
 1 = "Male"
 2 = "Female";
run;

%let exp_vars =
 TOTEXP07 DVTEXP07 RXEXP07  OBVEXP07 OBDEXP07
 OBOEXP07 OPTEXP07 OPYEXP07 OPZEXP07 ERTEXP07
 IPTEXP07 HHTEXP07 OMAEXP07;

data MEPS_gt0; set MEPS;
 array vars &exp_vars.;
 do over vars;
  if vars <= 0 then vars = .;
 end;
run;

ods output DomainQuantiles = out;
proc surveymeans data = MEPS_gt0 median nobs nomcar;
 FORMAT sex sex.;
 VAR &exp_vars.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT07F;
 DOMAIN sex;
run;

proc print data = out;
run;
