
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

/* Event type and source of payment */
  %macro add_sops(event);
    if year <= 1999 then do;
      &event.TRI&yy. = &event.CHM&yy.;
    end;

    &event.OTH&yy. = &event.OFD&yy. + &event.STL&yy. + &event.OPR&yy. + &event.OPU&yy. + &event.OSR&yy.;
    &event.OTZ&yy. = &event.OTH&yy. + &event.WCP&yy. + &event.VA&yy.;
    &event.PTR&yy. = &event.PRV&yy. + &event.TRI&yy.;
  %mend;

  %macro add_events(sop);
    HHT&sop.&yy. = HHA&sop.&yy. + HHN&sop.&yy.; /* Home Health Agency + Independent providers */
    ERT&sop.&yy. = ERF&sop.&yy. + ERD&sop.&yy.; /* Doctor + Facility expenses for OP, ER, IP events */
    IPT&sop.&yy. = IPF&sop.&yy. + IPD&sop.&yy.;
    OPT&sop.&yy. = OPF&sop.&yy. + OPD&sop.&yy.; /* All Outpatient */
    OPY&sop.&yy. = OPV&sop.&yy. + OPS&sop.&yy.; /* Physician only */
    OPZ&sop.&yy. = OPO&sop.&yy. + OPP&sop.&yy.; /* Non-physician only */
    OMA&sop.&yy. = VIS&sop.&yy. + OTH&sop.&yy.;
  %mend;

  %macro add_event_sops;
    %let sops = EXP SLF PTR MCR MCD OTZ;
    %let events =
        TOT DVT RX  OBV OBD OBO
        OPF OPD OPV OPS OPO OPP
        ERF ERD IPF IPD HHA HHN
        VIS OTH;

    data MEPS; set MEPS;
      %do i = 1 %to 20;
        %add_sops(event = %scan(&events, &i));
      %end;

      %do i = 1 %to 6;
        %add_events(sop = %scan(&sops, &i));
      %end;
    run;
  %mend;

  %add_event_sops;

%let exp_vars =
  TOTEXP&yy. DVTEXP&yy. RXEXP&yy.  OBVEXP&yy. OBDEXP&yy.
  OBOEXP&yy. OPTEXP&yy. OPYEXP&yy. OPZEXP&yy. ERTEXP&yy.
  IPTEXP&yy. HHTEXP&yy. OMAEXP&yy.

  TOTSLF&yy. DVTSLF&yy.  RXSLF&yy.  OBVSLF&yy. OBDSLF&yy.
  OBOSLF&yy. OPTSLF&yy.  OPYSLF&yy. OPZSLF&yy. ERTSLF&yy.
  IPTSLF&yy. HHTSLF&yy.  OMASLF&yy.

  TOTPTR&yy. DVTPTR&yy. RXPTR&yy.  OBVPTR&yy. OBDPTR&yy.
  OBOPTR&yy. OPTPTR&yy. OPYPTR&yy. OPZPTR&yy.  ERTPTR&yy.
  IPTPTR&yy. HHTPTR&yy. OMAPTR&yy.

  TOTMCR&yy. DVTMCR&yy. RXMCR&yy. OBVMCR&yy. OBDMCR&yy.
  OBOMCR&yy. OPTMCR&yy. OPYMCR&yy. OPZMCR&yy. ERTMCR&yy.
  IPTMCR&yy. HHTMCR&yy. OMAMCR&yy.

  TOTMCD&yy. DVTMCD&yy. RXMCD&yy.  OBVMCD&yy. OBDMCD&yy.
  OBOMCD&yy. OPTMCD&yy. OPYMCD&yy. OPZMCD&yy. ERTMCD&yy.
  IPTMCD&yy. HHTMCD&yy. OMAMCD&yy.

  TOTOTZ&yy. DVTOTZ&yy. RXOTZ&yy.  OBVOTZ&yy. OBDOTZ&yy.
  OBOOTZ&yy. OPTOTZ&yy. OPYOTZ&yy. OPZOTZ&yy. ERTOTZ&yy.
  IPTOTZ&yy. HHTOTZ&yy. OMAOTZ&yy.;

ods output Domain = out;
proc surveymeans data = MEPS sum missing nobs;
  FORMAT ind ind.;
  VAR &exp_vars.;
  STRATA VARSTR;
  CLUSTER VARPSU;
  WEIGHT PERWT&yy.F;
  DOMAIN ind;
run;

proc print data = out;
run;

