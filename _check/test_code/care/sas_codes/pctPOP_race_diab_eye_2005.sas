ods graphics off;

/* Read in dataset and initialize year */
FILENAME h97 "C:\MEPS\h97.ssp";
proc xcopy in = h97 out = WORK IMPORT;
run;

data MEPS;
 SET h97;
 year = 2005;
 ind = 1;
 count = 1;

 /* Create AGELAST variable */
 if AGE05X >= 0 then AGELAST=AGE05x;
 else if AGE42X >= 0 then AGELAST=AGE42X;
 else if AGE31X >= 0 then AGELAST=AGE31X;
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

/* Diabetes care: Eye exam */
data MEPS; set MEPS;

 past_year = (DSEY0553=1 | DSEY0653=1);
 more_year = (DSEY0453=1 | DSEB0453=1);
 never_chk = (DSEYNV53 = 1);
 non_resp = (DSEY0553 in (-7,-8,-9));

 if past_year = 1 then diab_eye = 1;
 else if more_year = 1 then diab_eye = 2;
 else if never_chk = 1 then diab_eye = 3;
 else if non_resp = 1  then diab_eye = -7;
 else diab_eye = -9;

 if diabw05f>0 then domain=1;
 else do;
   domain=2;
   diabw05f=1;
 end;
run;

proc format;
 value diab_eye
  1 = "In the past year"
  2 = "More than 1 year ago"
  3 = "Never had eye exam"
  4 = "No exam in past year"
 -1 = "Inapplicable"
 -7 = "Don't know/Non-response"
 -9 = "Missing";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
 FORMAT diab_eye diab_eye. race race.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT DIABW05F;
 TABLES domain*race*diab_eye / row;
run;

proc print data = out;
 where domain = 1 and diab_eye ne . and race ne .;
 var diab_eye race WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
