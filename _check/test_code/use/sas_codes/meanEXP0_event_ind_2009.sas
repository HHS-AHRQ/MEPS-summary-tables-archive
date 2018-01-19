ods graphics off;

/* Read in dataset and initialize year */
FILENAME h129 "C:\MEPS\h129.ssp";
proc xcopy in = h129 out = WORK IMPORT;
run;

data MEPS;
 SET h129;
 ARRAY OLDVAR(5) VARPSU09 VARSTR09 WTDPER09 AGE2X AGE1X;
 year = 2009;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU09;
  VARSTR = VARSTR09;
 end;

 if year <= 1998 then do;
  PERWT09F = WTDPER09;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE09X >= 0 then AGELAST = AGE09x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Event type */
data MEPS; set MEPS;
 HHTEXP09 = HHAEXP09 + HHNEXP09; /* Home Health Agency + Independent providers */
 ERTEXP09 = ERFEXP09 + ERDEXP09; /* Doctor + Facility Expenses for OP, ER, IP events */
 IPTEXP09 = IPFEXP09 + IPDEXP09;
 OPTEXP09 = OPFEXP09 + OPDEXP09; /* All Outpatient */
 OPYEXP09 = OPVEXP09 + OPSEXP09; /* Physician only */
 OPZEXP09 = OPOEXP09 + OPPEXP09; /* non-physician only */
 OMAEXP09 = VISEXP09 + OTHEXP09;

 TOTUSE09 = 
  ((DVTOT09 > 0) + (RXTOT09 > 0) + (OBTOTV09 > 0) +
  (OPTOTV09 > 0) + (ERTOT09 > 0) + (IPDIS09 > 0) +
  (HHTOTD09 > 0) + (OMAEXP09 > 0));
run;

%let exp_vars =
 TOTEXP09 DVTEXP09 RXEXP09  OBVEXP09 OBDEXP09
 OBOEXP09 OPTEXP09 OPYEXP09 OPZEXP09 ERTEXP09
 IPTEXP09 HHTEXP09 OMAEXP09;

ods output Domain = out;
proc surveymeans data = MEPS mean missing nobs;
 FORMAT ind ind.;
 VAR &exp_vars.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT09F;
 DOMAIN ind;
run;

proc print data = out;
run;
