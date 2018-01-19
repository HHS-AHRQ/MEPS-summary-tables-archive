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

/* Education */
data MEPS; set MEPS;
 ARRAY EDUVARS(4) EDUCYR98 EDUCYR EDUCYEAR EDRECODE;
 if year <= 1998 then EDUCYR = EDUCYR98;
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

data MEPS_gt0; set MEPS;
 if TOTEXP98 <= 0 then TOTEXP98 = .;
run;

ods output DomainQuantiles = out;
proc surveymeans data = MEPS_gt0 median nobs nomcar;
 FORMAT ind ind. education education.;
 VAR TOTEXP98;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT98F;
 DOMAIN ind*education;
run;

proc print data = out;
run;
