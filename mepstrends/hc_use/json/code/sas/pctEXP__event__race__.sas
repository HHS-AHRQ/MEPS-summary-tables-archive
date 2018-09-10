
ods graphics off;

/* Read in FYC dataset and initialize year */
  FILENAME &FYC. "C:\MEPS\&FYC..ssp";
  proc xcopy in = &FYC. out = WORK IMPORT;
  run;

  data MEPS;
    SET &FYC.;
    ARRAY OLDVAR(5) VARPSU&yy. VARSTR&yy. WTDPER&yy. AGE2X AGE1X;
    year = &year.;
    ind = 1;
    count = 1;

    if year <= 2001 then do;
      VARPSU = VARPSU&yy.;
      VARSTR = VARSTR&yy.;
    end;

    if year <= 1998 then do;
      PERWT&yy.F = WTDPER&yy.;
    end;

    /* Create AGELAST variable */
    if year = 1996 then do;
      AGE42X = AGE2X;
      AGE31X = AGE1X;
    end;

    if AGE&yy.X >= 0 then AGELAST = AGE&yy.x;
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
    HHTEXP&yy. = HHAEXP&yy. + HHNEXP&yy.; /* Home Health Agency + Independent providers */
    ERTEXP&yy. = ERFEXP&yy. + ERDEXP&yy.; /* Doctor + Facility Expenses for OP, ER, IP events */
    IPTEXP&yy. = IPFEXP&yy. + IPDEXP&yy.;
    OPTEXP&yy. = OPFEXP&yy. + OPDEXP&yy.; /* All Outpatient */
    OPYEXP&yy. = OPVEXP&yy. + OPSEXP&yy.; /* Physician only */
    OPZEXP&yy. = OPOEXP&yy. + OPPEXP&yy.; /* non-physician only */
    OMAEXP&yy. = VISEXP&yy. + OTHEXP&yy.;

    TOTUSE&yy. =
      ((DVTOT&yy. > 0) + (RXTOT&yy. > 0) + (OBTOTV&yy. > 0) +
      (OPTOTV&yy. > 0) + (ERTOT&yy. > 0) + (IPDIS&yy. > 0) +
      (HHTOTD&yy. > 0) + (OMAEXP&yy. > 0));
  run;

%let exp_vars =
  TOTEXP&yy. DVTEXP&yy. RXEXP&yy.  OBVEXP&yy. OBDEXP&yy.
  OBOEXP&yy. OPTEXP&yy. OPYEXP&yy. OPZEXP&yy. ERTEXP&yy.
  IPTEXP&yy. HHTEXP&yy. OMAEXP&yy.;

data MEPS_gt0; set MEPS;
  array vars &exp_vars.;
  do over vars;
    vars = (vars > 0);
  end;
run;

ods output Domain = out;
proc surveymeans data = MEPS_gt0 mean missing nobs;
  FORMAT race race.;
  VAR &exp_vars.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  DOMAIN race;
run;

proc print data = out;
run;

