ods graphics off;

/* Read in dataset and initialize year */
FILENAME h105 "C:\MEPS\h105.ssp";
proc xcopy in = h105 out = WORK IMPORT;
run;

data MEPS;
 SET h105;
 ARRAY OLDVAR(5) VARPSU06 VARSTR06 WTDPER06 AGE2X AGE1X;
 year = 2006;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU06;
  VARSTR = VARSTR06;
 end;

 if year <= 1998 then do;
  PERWT06F = WTDPER06;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE06X >= 0 then AGELAST = AGE06x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Race/ethnicity */
data MEPS; set MEPS;
 ARRAY RCEVAR(4) RACETHX RACEV1X RACETHNX RACEX;
 if year >= 2012 then do;
  hisp   = (RACETHX = 1);
   white  = (RACETHX = 2);
       black  = (RACETHX = 3);
       native = (RACETHX > 3 and RACEV1X in (3,6));
       asian  = (RACETHX > 3 and RACEV1X in (4,5));
  white_oth = 0;
 end;

 else if year >= 2002 then do;
  hisp   = (RACETHNX = 1);
  white  = (RACETHNX = 4 and RACEX = 1);
  black  = (RACETHNX = 2);
  native = (RACETHNX >= 3 and RACEX in (3,6));
  asian  = (RACETHNX >= 3 and RACEX in (4,5));
  white_oth = 0;
 end;

 else do;
  hisp  = (RACETHNX = 1);
  black = (RACETHNX = 2);
  white_oth = (RACETHNX = 3);
  white  = 0;
  native = 0;
  asian  = 0;
 end;

 race = 1*hisp + 2*white + 3*black + 4*native + 5*asian + 9*white_oth;
run;

proc format;
 value race
 1 = "Hispanic"
 2 = "White"
 3 = "Black"
 4 = "Amer. Indian, AK Native, or mult. races"
 5 = "Asian, Hawaiian, or Pacific Islander"
 9 = "White and other"
 . = "Missing";
run;

/* Event type */
data MEPS; set MEPS;
 HHTEXP06 = HHAEXP06 + HHNEXP06; /* Home Health Agency + Independent providers */
 ERTEXP06 = ERFEXP06 + ERDEXP06; /* Doctor + Facility Expenses for OP, ER, IP events */
 IPTEXP06 = IPFEXP06 + IPDEXP06;
 OPTEXP06 = OPFEXP06 + OPDEXP06; /* All Outpatient */
 OPYEXP06 = OPVEXP06 + OPSEXP06; /* Physician only */
 OPZEXP06 = OPOEXP06 + OPPEXP06; /* non-physician only */
 OMAEXP06 = VISEXP06 + OTHEXP06;

 TOTUSE06 = 
  ((DVTOT06 > 0) + (RXTOT06 > 0) + (OBTOTV06 > 0) +
  (OPTOTV06 > 0) + (ERTOT06 > 0) + (IPDIS06 > 0) +
  (HHTOTD06 > 0) + (OMAEXP06 > 0));
run;

%let use_vars =
 TOTUSE06 DVTOT06  RXTOT06 OBTOTV06 OBDRV06
 OBOTHV06 OPTOTV06 OPDRV06 OPOTHV06 ERTOT06
 IPDIS06  HHTOTD06 OMAEXP06;

data MEPS_use; set MEPS;
 array vars &use_vars.;
 do over vars;
  vars = (vars > 0);
 end;
run;

ods output Domain = out;
proc surveymeans data = MEPS_use sum missing nobs;
 FORMAT race race.;
 VAR &use_vars.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT06F;
 DOMAIN race;
run;

proc print data = out;
run;
