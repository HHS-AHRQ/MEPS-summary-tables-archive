
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

/* Sex */
  proc format;
    value sex
    1 = "Male"
    2 = "Female";
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

* Macro to load event files **************************************************;

  %macro load_events(evnt,file) / minoperator;

    FILENAME &file. "C:\MEPS\&file..ssp";
    proc xcopy in = &file. out = WORK IMPORT;
    run;

    data &evnt;
      SET &syslast; /* Most recent dataset loaded */
      ARRAY OLDVARS(2) LINKIDX EVNTIDX;
      event = "&evnt.";
      year = &year.;

      %if &evnt in (IP OP ER) %then %do;
      ARRAY OLDVARS2(3) &evnt.DCH&yy.X &evnt.FCH&yy.X SEEDOC ;
        SF&yy.X = &evnt.DSF&yy.X + &evnt.FSF&yy.X;
        MR&yy.X = &evnt.DMR&yy.X + &evnt.FMR&yy.X;
        MD&yy.X = &evnt.DMD&yy.X + &evnt.FMD&yy.X;
        PV&yy.X = &evnt.DPV&yy.X + &evnt.FPV&yy.X;
        VA&yy.X = &evnt.DVA&yy.X + &evnt.FVA&yy.X;
        OF&yy.X = &evnt.DOF&yy.X + &evnt.FOF&yy.X;
        SL&yy.X = &evnt.DSL&yy.X + &evnt.FSL&yy.X;
        WC&yy.X = &evnt.DWC&yy.X + &evnt.FWC&yy.X;
        OR&yy.X = &evnt.DOR&yy.X + &evnt.FOR&yy.X;
        OU&yy.X = &evnt.DOU&yy.X + &evnt.FOU&yy.X;
        OT&yy.X = &evnt.DOT&yy.X + &evnt.FOT&yy.X;
        XP&yy.X = &evnt.DXP&yy.X + &evnt.FXP&yy.X;

        if year <= 1999 then TR&yy.X = &evnt.DCH&yy.X + &evnt.FCH&yy.X;
        else TR&yy.X = &evnt.DTR&yy.X + &evnt.FTR&yy.X;
      %end;

      %else %do;
      ARRAY OLDVARS2(2) &evnt.CH&yy.X SEEDOC ;
        SF&yy.X = &evnt.SF&yy.X;
        MR&yy.X = &evnt.MR&yy.X;
        MD&yy.X = &evnt.MD&yy.X;
        PV&yy.X = &evnt.PV&yy.X;
        VA&yy.X = &evnt.VA&yy.X;
        OF&yy.X = &evnt.OF&yy.X;
        SL&yy.X = &evnt.SL&yy.X;
        WC&yy.X = &evnt.WC&yy.X;
        OR&yy.X = &evnt.OR&yy.X;
        OU&yy.X = &evnt.OU&yy.X;
        OT&yy.X = &evnt.OT&yy.X;
        XP&yy.X = &evnt.XP&yy.X;

        if year <= 1999 then TR&yy.X = &evnt.CH&yy.X;
        else TR&yy.X = &evnt.TR&yy.X;
      %end;

      PR&yy.X = PV&yy.X + TR&yy.X;
      OZ&yy.X = OF&yy.X + SL&yy.X + OT&yy.X + OR&yy.X + OU&yy.X + WC&yy.X + VA&yy.X;

      keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP&yy.X SF&yy.X PR&yy.X MR&yy.X MD&yy.X OZ&yy.X;
    run;
  %mend;

/* Load event files */
  %load_events(RX,&RX.);
  %load_events(DV,&DV.);
  %load_events(IP,&IP.);
  %load_events(ER,&ER.);
  %load_events(OP,&OP.);
  %load_events(OB,&OB.);
  %load_events(HH,&HH.);

/* Define sub-levels for office-based, outpatient, and home health */
/* To compute estimates for these sub-events, replace 'event' with 'event_v2X'
   in the 'proc surveymeans' statement below, when applicable */

  data OB; set OB;
    if SEEDOC = 1 then event_v2X = 'OBD';
    else if SEEDOC = 2 then event_v2X = 'OBO';
    else event_v2X = '';
  run;

  data OP; set OP;
    if SEEDOC = 1 then event_v2X = 'OPY';
    else if SEEDOC = 2 then event_v2X = 'OPZ';
    else event_v2X = '';
  run;

/* Merge with FYC file */
  data FYCsub; set MEPS;
    keep race sex DUPERSID PERWT&yy.F VARSTR VARPSU;
  run;

  data stacked_events;
    set RX DV IP ER OP OB HH;
  run;

  proc sort data = stacked_events; by DUPERSID; run;
  proc sort data = FYCsub; by DUPERSID; run;

  data EVENTS;
    merge stacked_events FYCsub;
    by DUPERSID;
  run;

data EVENTS_ge0; set EVENTS;
  XP&yy.X = (XP&yy.X >= 0);
run;

ods output Domain = out;
proc surveymeans data = EVENTS_ge0 sum missing nobs;
  FORMAT race race. sex sex.;
  VAR XP&yy.X;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  DOMAIN race*sex;
run;

proc print data = out;
run;

