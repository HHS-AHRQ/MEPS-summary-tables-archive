ods graphics off;

/* Read in dataset and initialize year */
FILENAME h38 "C:\MEPS\h38.ssp";
proc xcopy in = h38 out = WORK IMPORT;
run;

data MEPS;
 SET h38;
 ARRAY OLDVAR(5) VARPSU99 VARSTR99 WTDPER99 AGE2X AGE1X;
 year = 1999;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU99;
  VARSTR = VARSTR99;
 end;

 if year <= 1998 then do;
  PERWT99F = WTDPER99;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE99X >= 0 then AGELAST = AGE99x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Event type and source of payment */
%macro add_sops(event);
 if year <= 1999 then do;
  &event.TRI99 = &event.CHM99;
 end;

 &event.OTH99 = &event.OFD99 + &event.STL99 + &event.OPR99 + &event.OPU99 + &event.OSR99;
 &event.OTZ99 = &event.OTH99 + &event.WCP99 + &event.VA99;
 &event.PTR99 = &event.PRV99 + &event.TRI99;
%mend;

%macro add_events(sop);
 HHT&sop.99 = HHA&sop.99 + HHN&sop.99; /* Home Health Agency + Independent providers */
 ERT&sop.99 = ERF&sop.99 + ERD&sop.99; /* Doctor + Facility expenses for OP, ER, IP events */
 IPT&sop.99 = IPF&sop.99 + IPD&sop.99;
 OPT&sop.99 = OPF&sop.99 + OPD&sop.99; /* All Outpatient */
 OPY&sop.99 = OPV&sop.99 + OPS&sop.99; /* Physician only */
 OPZ&sop.99 = OPO&sop.99 + OPP&sop.99; /* Non-physician only */
 OMA&sop.99 = VIS&sop.99 + OTH&sop.99;
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
 TOTEXP99 DVTEXP99 RXEXP99  OBVEXP99 OBDEXP99
 OBOEXP99 OPTEXP99 OPYEXP99 OPZEXP99 ERTEXP99
 IPTEXP99 HHTEXP99 OMAEXP99

 TOTSLF99 DVTSLF99 RXSLF99  OBVSLF99 OBDSLF99
 OBOSLF99 OPTSLF99 OPYSLF99 OPZSLF99 ERTSLF99
 IPTSLF99 HHTSLF99 OMASLF99

 TOTPTR99 DVTPTR99 RXPTR99  OBVPTR99 OBDPTR99
 OBOPTR99 OPTPTR99 OPYPTR99 OPZPTR99 ERTPTR99
 IPTPTR99 HHTPTR99 OMAPTR99

 TOTMCR99 DVTMCR99 RXMCR99 OBVMCR99 OBDMCR99
 OBOMCR99 OPTMCR99 OPYMCR99 OPZMCR99 ERTMCR99
 IPTMCR99 HHTMCR99 OMAMCR99

 TOTMCD99 DVTMCD99 RXMCD99  OBVMCD99 OBDMCD99
 OBOMCD99 OPTMCD99 OPYMCD99 OPZMCD99 ERTMCD99
 IPTMCD99 HHTMCD99 OMAMCD99

 TOTOTZ99 DVTOTZ99 RXOTZ99  OBVOTZ99 OBDOTZ99
 OBOOTZ99 OPTOTZ99 OPYOTZ99 OPZOTZ99 ERTOTZ99
 IPTOTZ99 HHTOTZ99 OMAOTZ99;

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
 WEIGHT PERWT99F;
 DOMAIN ind;
run;

proc print data = out;
run;
