ods graphics off;

/* Read in dataset and initialize year */
FILENAME h171 "C:\MEPS\h171.ssp";
proc xcopy in = h171 out = WORK IMPORT;
run;

data MEPS;
 SET h171;
 ARRAY OLDVAR(5) VARPSU14 VARSTR14 WTDPER14 AGE2X AGE1X;
 year = 2014;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU14;
  VARSTR = VARSTR14;
 end;

 if year <= 1998 then do;
  PERWT14F = WTDPER14;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE14X >= 0 then AGELAST = AGE14x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Event type */
data MEPS; set MEPS;
 HHTEXP14 = HHAEXP14 + HHNEXP14; /* Home Health Agency + Independent providers */
 ERTEXP14 = ERFEXP14 + ERDEXP14; /* Doctor + Facility Expenses for OP, ER, IP events */
 IPTEXP14 = IPFEXP14 + IPDEXP14;
 OPTEXP14 = OPFEXP14 + OPDEXP14; /* All Outpatient */
 OPYEXP14 = OPVEXP14 + OPSEXP14; /* Physician only */
 OPZEXP14 = OPOEXP14 + OPPEXP14; /* non-physician only */
 OMAEXP14 = VISEXP14 + OTHEXP14;

 TOTUSE14 = 
  ((DVTOT14 > 0) + (RXTOT14 > 0) + (OBTOTV14 > 0) +
  (OPTOTV14 > 0) + (ERTOT14 > 0) + (IPDIS14 > 0) +
  (HHTOTD14 > 0) + (OMAEXP14 > 0));
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

%let exp_vars =
 TOTEXP14 DVTEXP14 RXEXP14  OBVEXP14 OBDEXP14
 OBOEXP14 OPTEXP14 OPYEXP14 OPZEXP14 ERTEXP14
 IPTEXP14 HHTEXP14 OMAEXP14;

ods output Domain = out;
proc surveymeans data = MEPS sum missing nobs;
 FORMAT mnhlth mnhlth.;
 VAR &exp_vars.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT14F;
 DOMAIN mnhlth;
run;

proc print data = out;
run;
