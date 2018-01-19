ods graphics off;

/* Read in dataset and initialize year */
FILENAME h12 "C:\MEPS\h12.ssp";
proc xcopy in = h12 out = WORK IMPORT;
run;

data MEPS;
 SET h12;
 ARRAY OLDVAR(5) VARPSU96 VARSTR96 WTDPER96 AGE2X AGE1X;
 year = 1996;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU96;
  VARSTR = VARSTR96;
 end;

 if year <= 1998 then do;
  PERWT96F = WTDPER96;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE96X >= 0 then AGELAST = AGE96x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Event type and source of payment */
%macro add_sops(event);
 if year <= 1999 then do;
  &event.TRI96 = &event.CHM96;
 end;

 &event.OTH96 = &event.OFD96 + &event.STL96 + &event.OPR96 + &event.OPU96 + &event.OSR96;
 &event.OTZ96 = &event.OTH96 + &event.WCP96 + &event.VA96;
 &event.PTR96 = &event.PRV96 + &event.TRI96;
%mend;

%macro add_events(sop);
 HHT&sop.96 = HHA&sop.96 + HHN&sop.96; /* Home Health Agency + Independent providers */
 ERT&sop.96 = ERF&sop.96 + ERD&sop.96; /* Doctor + Facility expenses for OP, ER, IP events */
 IPT&sop.96 = IPF&sop.96 + IPD&sop.96;
 OPT&sop.96 = OPF&sop.96 + OPD&sop.96; /* All Outpatient */
 OPY&sop.96 = OPV&sop.96 + OPS&sop.96; /* Physician only */
 OPZ&sop.96 = OPO&sop.96 + OPP&sop.96; /* Non-physician only */
 OMA&sop.96 = VIS&sop.96 + OTH&sop.96;
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
 TOTEXP96 DVTEXP96 RXEXP96  OBVEXP96 OBDEXP96
 OBOEXP96 OPTEXP96 OPYEXP96 OPZEXP96 ERTEXP96
 IPTEXP96 HHTEXP96 OMAEXP96

 TOTSLF96 DVTSLF96 RXSLF96  OBVSLF96 OBDSLF96
 OBOSLF96 OPTSLF96 OPYSLF96 OPZSLF96 ERTSLF96
 IPTSLF96 HHTSLF96 OMASLF96

 TOTPTR96 DVTPTR96 RXPTR96  OBVPTR96 OBDPTR96
 OBOPTR96 OPTPTR96 OPYPTR96 OPZPTR96 ERTPTR96
 IPTPTR96 HHTPTR96 OMAPTR96

 TOTMCR96 DVTMCR96 RXMCR96 OBVMCR96 OBDMCR96
 OBOMCR96 OPTMCR96 OPYMCR96 OPZMCR96 ERTMCR96
 IPTMCR96 HHTMCR96 OMAMCR96

 TOTMCD96 DVTMCD96 RXMCD96  OBVMCD96 OBDMCD96
 OBOMCD96 OPTMCD96 OPYMCD96 OPZMCD96 ERTMCD96
 IPTMCD96 HHTMCD96 OMAMCD96

 TOTOTZ96 DVTOTZ96 RXOTZ96  OBVOTZ96 OBDOTZ96
 OBOOTZ96 OPTOTZ96 OPYOTZ96 OPZOTZ96 ERTOTZ96
 IPTOTZ96 HHTOTZ96 OMAOTZ96;

data MEPS_gt0; set MEPS;
 array vars &exp_vars.;
 do over vars;
  vars = (vars > 0);
 end;
run;

ods output Domain = out;
proc surveymeans data = MEPS_gt0 mean missing nobs;
 FORMAT ind ind.;
 VAR &exp_vars.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT96F;
 DOMAIN ind;
run;

proc print data = out;
run;
