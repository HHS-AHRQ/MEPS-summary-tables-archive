
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

/* Age groups */
/* To compute for additional age groups, replace 'agegrps' in the SURVEY procedure with 'agegrps_v2X'  */
  data MEPS; set MEPS;
    agegrps = AGELAST;
    agegrps_v2X = AGELAST;
    agegrps_v3X = AGELAST;
  run;

  proc format;
    value agegrps
    low-4 = "Under 5"
    5-17  = "5-17"
    18-44 = "18-44"
    45-64 = "45-64"
    65-high = "65+";

    value agegrps_v2X
    low-17  = "Under 18"
    18-64   = "18-64"
    65-high = "65+";

    value agegrps_v3X
    low-4 = "Under 5"
    5-6   = "5-6"
    7-12  = "7-12"
    13-17 = "13-17"
    18    = "18"
    19-24 = "19-24"
    25-29 = "25-29"
    30-34 = "30-34"
    35-44 = "35-44"
    45-54 = "45-54"
    55-64 = "55-64"
    65-high = "65+";
  run;

/* Perceived health status */
  data MEPS; set MEPS;
    ARRAY OLDHLT(2) RTEHLTH1 RTEHLTH2;
    if year = 1996 then do;
      RTHLTH53 = RTEHLTH2;
      RTHLTH42 = RTEHLTH2;
      RTHLTH31 = RTEHLTH1;
    end;

    if RTHLTH53 >= 0 then health = RTHLTH53;
    else if RTHLTH42 >= 0 then health = RTHLTH42;
    else if RTHLTH31 >= 0 then health = RTHLTH31;
    else health = .;
  run;

  proc format;
    value health
    1 = "Excellent"
    2 = "Very good"
    3 = "Good"
    4 = "Fair"
    5 = "Poor"
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
    keep health agegrps DUPERSID PERWT&yy.F VARSTR VARPSU;
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
  FORMAT health health. agegrps agegrps.;
  VAR XP&yy.X;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  DOMAIN health*agegrps;
run;

proc print data = out;
run;

