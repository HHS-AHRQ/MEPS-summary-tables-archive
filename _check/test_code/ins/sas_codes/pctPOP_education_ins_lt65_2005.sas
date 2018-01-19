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

/* Insurance coverage */
/* To compute for insurance categories, replace 'insurance' in the SURVEY procedure with 'insurance_v2X' */
data MEPS; set MEPS;
 ARRAY OLDINS(4) MCDEVER MCREVER OPAEVER OPBEVER;
 if year = 1996 then do;
  MCDEV96 = MCDEVER;
  MCREV96 = MCREVER;
  OPAEV96 = OPAEVER;
  OPBEV96 = OPBEVER;
 end;

 if year < 2011 then do;
  public   = (MCDEV05 = 1) or (OPAEV05=1) or (OPBEV05=1);
  medicare = (MCREV05=1);
  private  = (INSCOV05=1);

  mcr_priv = (medicare and  private);
  mcr_pub  = (medicare and ~private and public);
  mcr_only = (medicare and ~private and ~public);
  no_mcr   = (~medicare);

  ins_gt65 = 4*mcr_only + 5*mcr_priv + 6*mcr_pub + 7*no_mcr;

  if AGELAST < 65 then INSURC05 = INSCOV05;
  else INSURC05 = ins_gt65;
 end;

 insurance = INSCOV05;
 insurance_v2X = INSURC05;
run;

proc format;
 value insurance
 1 = "Any private, all ages"
 2 = "Public only, all ages"
 3 = "Uninsured, all ages";

 value insurance_v2X
 1 = "<65, Any private"
 2 = "<65, Public only"
 3 = "<65, Uninsured"
 4 = "65+, Medicare only"
 5 = "65+, Medicare and private"
 6 = "65+, Medicare and other public"
 7 = "65+, No medicare"
 8 = "65+, No medicare";
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

data MEPS;
 set MEPS;
 domain = (AGELAST < 65);
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
 FORMAT education education. insurance_v2X insurance_v2X.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT05F;
 TABLES domain*education*insurance_v2X / row;
run;

proc print data = out;
 where insurance_v2X ne . ;
 var domain education insurance_v2X Frequency WgtFreq StdDev RowPercent RowStdErr;
run;
