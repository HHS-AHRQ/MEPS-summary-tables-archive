ods graphics off;

/* Read in dataset and initialize year */
FILENAME h121 "C:\MEPS\h121.ssp";
proc xcopy in = h121 out = WORK IMPORT;
run;

data MEPS;
 SET h121;
 year = 2008;
 ind = 1;
 count = 1;

 /* Create AGELAST variable */
 if AGE08X >= 0 then AGELAST=AGE08x;
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

/* Diabetes care: Foot care */
data MEPS; set MEPS;
 ARRAY FTVAR(5) DSCKFT53 DSFTNV53 DSFT0753 DSFT0853 DSFT0953;
 if year > 2007 then do;
  past_year = (DSFT0853=1 | DSFT0953=1);
  more_year = (DSFT0753=1 | DSFB0753=1);
  never_chk = (DSFTNV53 = 1);
  non_resp  = (DSFT0853 in (-7,-8,-9));
  inapp     = (DSFT0853 = -1);
 end;

 else do;
  past_year = (DSCKFT53 >= 1);
  not_past_year = (DSCKFT53 = 0);
  non_resp  = (DSCKFT53 in (-7,-8,-9));
  inapp     = (DSCKFT53 = -1);
 end;

 if past_year = 1 then diab_foot = 1;
 else if more_year = 1 then diab_foot = 2;
 else if never_chk = 1 then diab_foot = 3;
 else if not_past_year = 1 then diab_foot = 4;
 else if inapp = 1     then diab_foot = -1;
 else if non_resp = 1  then diab_foot = -7;
 else diab_foot = -9;

 if diabw08f>0 then domain=1;
 else do;
   domain=2;
   diabw08f=1;
 end;
run;

proc format;
 value diab_foot
  1 = "In the past year"
  2 = "More than 1 year ago"
  3 = "Never had feet checked"
  4 = "No exam in past year"
 -1 = "Inapplicable"
 -7 = "Don't know/Non-response"
 -9 = "Missing";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
 FORMAT diab_foot diab_foot. race race.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT DIABW08F;
 TABLES domain*race*diab_foot / row;
run;

proc print data = out;
 where domain = 1 and diab_foot ne . and race ne .;
 var diab_foot race WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
