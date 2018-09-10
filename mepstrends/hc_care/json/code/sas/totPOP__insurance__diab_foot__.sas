
ods graphics off;

/* Read in dataset and initialize year */
  FILENAME &FYC. "C:\MEPS\&FYC..ssp";
  proc xcopy in = &FYC. out = WORK IMPORT;
  run;

  data MEPS;
    SET &FYC.;
    year = &year.;
    ind = 1;
    count = 1;

    /* Create AGELAST variable */
    if AGE&yy.X >= 0 then AGELAST=AGE&yy.x;
    else if AGE42X >= 0 then AGELAST=AGE42X;
    else if AGE31X >= 0 then AGELAST=AGE31X;
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
      public   = (MCDEV&yy. = 1) or (OPAEV&yy.=1) or (OPBEV&yy.=1);
      medicare = (MCREV&yy.=1);
      private  = (INSCOV&yy.=1);

      mcr_priv = (medicare and  private);
      mcr_pub  = (medicare and ~private and public);
      mcr_only = (medicare and ~private and ~public);
      no_mcr   = (~medicare);

      ins_gt65 = 4*mcr_only + 5*mcr_priv + 6*mcr_pub + 7*no_mcr;

      if AGELAST < 65 then INSURC&yy. = INSCOV&yy.;
      else INSURC&yy. = ins_gt65;
    end;

    insurance = INSCOV&yy.;
    insurance_v2X = INSURC&yy.;
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

/* Diabetes care: Foot care */
data MEPS; set MEPS;
  ARRAY FTVAR(5) DSCKFT53 DSFTNV53 DSFT&yb.53 DSFT&yy.53 DSFT&ya.53;
  if year > 2007 then do;
    past_year = (DSFT&yy.53=1 | DSFT&ya.53=1);
    more_year = (DSFT&yb.53=1 | DSFB&yb.53=1);
    never_chk = (DSFTNV53 = 1);
    non_resp  = (DSFT&yy.53 in (-7,-8,-9));
    inapp     = (DSFT&yy.53 = -1);
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

  if diabw&yy.f>0 then domain=1;
  else do;
    domain=2;
    diabw&yy.f=1;
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
  FORMAT diab_foot diab_foot. insurance insurance.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT DIABW&yy.F;
  TABLES domain*insurance*diab_foot / row;
run;

proc print data = out;
  where domain = 1 and diab_foot ne . and insurance ne .;
  var diab_foot insurance WgtFreq StdDev Frequency RowPercent RowStdErr;
run;

