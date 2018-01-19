ods graphics off;

/* Read in dataset and initialize year */
FILENAME h97 "C:\MEPS\h97.ssp";
proc xcopy in = h97 out = WORK IMPORT;
run;

data MEPS;
 SET h97;
 ARRAY OLDVAR(5) VARPSU05 VARSTR05 WTDPER05 AGE2X AGE1X;
 year = 2005;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU05;
  VARSTR = VARSTR05;
 end;

 if year <= 1998 then do;
  PERWT05F = WTDPER05;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE05X >= 0 then AGELAST = AGE05x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Education */
data MEPS; set MEPS;
 ARRAY EDUVARS(4) EDUCYR05 EDUCYR EDUCYEAR EDRECODE;
 if year <= 1998 then EDUCYR = EDUCYR05;
 else if year <= 2004 then EDUCYR = EDUCYEAR;

 if year >= 2012 then do;
  less_than_hs = (0 <= EDRECODE and EDRECODE < 13);
  high_school  = (EDRECODE = 13);
  some_college = (EDRECODE > 13);
 end;

 else do;
  less_than_hs = (0 <= EDUCYR and EDUCYR < 12);
  high_school  = (EDUCYR = 12);
  some_college = (EDUCYR > 12);
 end;

 education = 1*less_than_hs + 2*high_school + 3*some_college;

 if AGELAST < 18 then education = 9;
run;

proc format;
 value education
 1 = "Less than high school"
 2 = "High school"
 3 = "Some college"
 9 = "Inapplicable (age < 18)"
 0 = "Missing"
 . = "Missing";
run;

/* Event type */
data MEPS; set MEPS;
 HHTEXP05 = HHAEXP05 + HHNEXP05; /* Home Health Agency + Independent providers */
 ERTEXP05 = ERFEXP05 + ERDEXP05; /* Doctor + Facility Expenses for OP, ER, IP events */
 IPTEXP05 = IPFEXP05 + IPDEXP05;
 OPTEXP05 = OPFEXP05 + OPDEXP05; /* All Outpatient */
 OPYEXP05 = OPVEXP05 + OPSEXP05; /* Physician only */
 OPZEXP05 = OPOEXP05 + OPPEXP05; /* non-physician only */
 OMAEXP05 = VISEXP05 + OTHEXP05;

 TOTUSE05 = 
  ((DVTOT05 > 0) + (RXTOT05 > 0) + (OBTOTV05 > 0) +
  (OPTOTV05 > 0) + (ERTOT05 > 0) + (IPDIS05 > 0) +
  (HHTOTD05 > 0) + (OMAEXP05 > 0));
run;

%let exp_vars =
 TOTEXP05 DVTEXP05 RXEXP05  OBVEXP05 OBDEXP05
 OBOEXP05 OPTEXP05 OPYEXP05 OPZEXP05 ERTEXP05
 IPTEXP05 HHTEXP05 OMAEXP05;

data MEPS_gt0; set MEPS;
 array vars &exp_vars.;
 do over vars;
  if vars <= 0 then vars = .;
 end;
run;

ods output Domain = out;
proc surveymeans data = MEPS_gt0 mean nobs nomcar;
 FORMAT education education.;
 VAR &exp_vars.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT05F;
 DOMAIN education;
run;

proc print data = out;
run;
