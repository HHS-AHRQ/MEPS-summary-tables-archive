ods graphics off;

/* Read in dataset and initialize year */
FILENAME h113 "C:\MEPS\h113.ssp";
proc xcopy in = h113 out = WORK IMPORT;
run;

data MEPS;
 SET h113;
 year = 2007;
 ind = 1;
 count = 1;

 /* Create AGELAST variable */
 if AGE07X >= 0 then AGELAST=AGE07x;
 else if AGE42X >= 0 then AGELAST=AGE42X;
 else if AGE31X >= 0 then AGELAST=AGE31X;
run;

proc format;
 value ind 1 = "Total";
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

/* Diabetes care: Flu shot */
data MEPS; set MEPS;
 ARRAY FLUVAR(5) FLUSHT53 DSFLNV53 DSFL0653 DSFL0753 DSFL0853;
 if year > 2007 then do;
  past_year = (DSFL0753=1 | DSFL0853=1);
  more_year = (DSFL0653=1 | DSVB0653=1);
  never_chk = (DSFLNV53 = 1);
  non_resp  = (DSFL0753 in (-7,-8,-9));
 end;

 else do;
  past_year = (FLUSHT53 = 1);
  more_year = (1 < FLUSHT53 & FLUSHT53 < 6);
  never_chk = (FLUSHT53 = 6);
  non_resp  = (FLUSHT53 in (-7,-8,-9));
 end;

 if past_year = 1 then diab_flu = 1;
 else if more_year = 1 then diab_flu = 2;
 else if never_chk = 1 then diab_flu = 3;
 else if non_resp = 1  then diab_flu = -7;
 else diab_flu = -9;

 if diabw07f>0 then domain=1;
 else do;
   domain=2;
   diabw07f=1;
 end;
run;

proc format;
 value diab_flu
  1 = "In the past year"
  2 = "More than 1 year ago"
  3 = "Never had flu shot"
  4 = "No flu shot in past year"
 -1 = "Inapplicable"
 -7 = "Don't know/Non-response"
 -9 = "Missing";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
 FORMAT diab_flu diab_flu. mnhlth mnhlth.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT DIABW07F;
 TABLES domain*mnhlth*diab_flu / row;
run;

proc print data = out;
 where domain = 1 and diab_flu ne . and mnhlth ne .;
 var diab_flu mnhlth WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
