ods graphics off;

/* Read in dataset and initialize year */
FILENAME h28 "C:\MEPS\h28.ssp";
proc xcopy in = h28 out = WORK IMPORT;
run;

data MEPS;
 SET h28;
 ARRAY OLDVAR(5) VARPSU98 VARSTR98 WTDPER98 AGE2X AGE1X;
 year = 1998;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU98;
  VARSTR = VARSTR98;
 end;

 if year <= 1998 then do;
  PERWT98F = WTDPER98;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE98X >= 0 then AGELAST = AGE98x;
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

/* Event type */
data MEPS; set MEPS;
 HHTEXP98 = HHAEXP98 + HHNEXP98; /* Home Health Agency + Independent providers */
 ERTEXP98 = ERFEXP98 + ERDEXP98; /* Doctor + Facility Expenses for OP, ER, IP events */
 IPTEXP98 = IPFEXP98 + IPDEXP98;
 OPTEXP98 = OPFEXP98 + OPDEXP98; /* All Outpatient */
 OPYEXP98 = OPVEXP98 + OPSEXP98; /* Physician only */
 OPZEXP98 = OPOEXP98 + OPPEXP98; /* non-physician only */
 OMAEXP98 = VISEXP98 + OTHEXP98;

 TOTUSE98 = 
  ((DVTOT98 > 0) + (RXTOT98 > 0) + (OBTOTV98 > 0) +
  (OPTOTV98 > 0) + (ERTOT98 > 0) + (IPDIS98 > 0) +
  (HHTOTD98 > 0) + (OMAEXP98 > 0));
run;

%let exp_vars =
 TOTEXP98 DVTEXP98 RXEXP98  OBVEXP98 OBDEXP98
 OBOEXP98 OPTEXP98 OPYEXP98 OPZEXP98 ERTEXP98
 IPTEXP98 HHTEXP98 OMAEXP98;

data MEPS_gt0; set MEPS;
 array vars &exp_vars.;
 do over vars;
  vars = (vars > 0);
 end;
run;

ods output Domain = out;
proc surveymeans data = MEPS_gt0 mean missing nobs;
 FORMAT health health.;
 VAR &exp_vars.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT98F;
 DOMAIN health;
run;

proc print data = out;
run;
