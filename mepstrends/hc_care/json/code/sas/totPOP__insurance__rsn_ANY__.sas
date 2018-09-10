
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

/* Reason for difficulty receiving needed care */
data MEPS; set MEPS;
  delay_MD  = (MDUNAB42=1|MDDLAY42=1);
  delay_DN  = (DNUNAB42=1|DNDLAY42=1);
  delay_PM  = (PMUNAB42=1|PMDLAY42=1);

  afford_MD = (MDDLRS42=1|MDUNRS42=1);
  afford_DN = (DNDLRS42=1|DNUNRS42=1);
  afford_PM = (PMDLRS42=1|PMUNRS42=1);

  insure_MD = (MDDLRS42 in (2,3)|MDUNRS42 in (2,3));
  insure_DN = (DNDLRS42 in (2,3)|DNUNRS42 in (2,3));
  insure_PM = (PMDLRS42 in (2,3)|PMUNRS42 in (2,3));

  other_MD  = (MDDLRS42 > 3|MDUNRS42 > 3);
  other_DN  = (DNDLRS42 > 3|DNUNRS42 > 3);
  other_PM  = (PMDLRS42 > 3|PMUNRS42 > 3);

  delay_ANY  = (delay_MD |delay_DN |delay_PM);
  afford_ANY = (afford_MD|afford_DN|afford_PM);
  insure_ANY = (insure_MD|insure_DN|insure_PM);
  other_ANY  = (other_MD |other_DN |other_PM);

  domain = (ACCELI42 = 1 & delay_ANY=1);
run;

proc format;
  value afford 1 = "Couldn't afford";
  value insure 1 = "Insurance related";
  value other 1 = "Other";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
  FORMAT afford_ANY afford. insure_ANY insure. other_ANY other. insurance insurance.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  TABLES domain*insurance*(afford_ANY insure_ANY other_ANY) / row;
run;

proc print data = out;
  where domain = 1 and (afford_ANY > 0 or insure_ANY > 0 or other_ANY > 0) and insurance ne .;
  var afford_ANY insure_ANY other_ANY insurance WgtFreq StdDev Frequency RowPercent RowStdErr;
run;

