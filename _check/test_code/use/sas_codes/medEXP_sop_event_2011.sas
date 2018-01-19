ods graphics off;

/* Read in dataset and initialize year */
FILENAME h147 "C:\MEPS\h147.ssp";
proc xcopy in = h147 out = WORK IMPORT;
run;

data MEPS;
 SET h147;
 ARRAY OLDVAR(5) VARPSU11 VARSTR11 WTDPER11 AGE2X AGE1X;
 year = 2011;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU11;
  VARSTR = VARSTR11;
 end;

 if year <= 1998 then do;
  PERWT11F = WTDPER11;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE11X >= 0 then AGELAST = AGE11x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Event type and source of payment */
%macro add_sops(event);
 if year <= 1999 then do;
  &event.TRI11 = &event.CHM11;
 end;

 &event.OTH11 = &event.OFD11 + &event.STL11 + &event.OPR11 + &event.OPU11 + &event.OSR11;
 &event.OTZ11 = &event.OTH11 + &event.WCP11 + &event.VA11;
 &event.PTR11 = &event.PRV11 + &event.TRI11;
%mend;

%macro add_events(sop);
 HHT&sop.11 = HHA&sop.11 + HHN&sop.11; /* Home Health Agency + Independent providers */
 ERT&sop.11 = ERF&sop.11 + ERD&sop.11; /* Doctor + Facility expenses for OP, ER, IP events */
 IPT&sop.11 = IPF&sop.11 + IPD&sop.11;
 OPT&sop.11 = OPF&sop.11 + OPD&sop.11; /* All Outpatient */
 OPY&sop.11 = OPV&sop.11 + OPS&sop.11; /* Physician only */
 OPZ&sop.11 = OPO&sop.11 + OPP&sop.11; /* Non-physician only */
 OMA&sop.11 = VIS&sop.11 + OTH&sop.11;
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
 TOTEXP11 DVTEXP11 RXEXP11  OBVEXP11 OBDEXP11
 OBOEXP11 OPTEXP11 OPYEXP11 OPZEXP11 ERTEXP11
 IPTEXP11 HHTEXP11 OMAEXP11

 TOTSLF11 DVTSLF11 RXSLF11  OBVSLF11 OBDSLF11
 OBOSLF11 OPTSLF11 OPYSLF11 OPZSLF11 ERTSLF11
 IPTSLF11 HHTSLF11 OMASLF11

 TOTPTR11 DVTPTR11 RXPTR11  OBVPTR11 OBDPTR11
 OBOPTR11 OPTPTR11 OPYPTR11 OPZPTR11 ERTPTR11
 IPTPTR11 HHTPTR11 OMAPTR11

 TOTMCR11 DVTMCR11 RXMCR11 OBVMCR11 OBDMCR11
 OBOMCR11 OPTMCR11 OPYMCR11 OPZMCR11 ERTMCR11
 IPTMCR11 HHTMCR11 OMAMCR11

 TOTMCD11 DVTMCD11 RXMCD11  OBVMCD11 OBDMCD11
 OBOMCD11 OPTMCD11 OPYMCD11 OPZMCD11 ERTMCD11
 IPTMCD11 HHTMCD11 OMAMCD11

 TOTOTZ11 DVTOTZ11 RXOTZ11  OBVOTZ11 OBDOTZ11
 OBOOTZ11 OPTOTZ11 OPYOTZ11 OPZOTZ11 ERTOTZ11
 IPTOTZ11 HHTOTZ11 OMAOTZ11;
 
data MEPS_gt0; set MEPS;
 array vars &exp_vars.;
 do over vars;
  if vars <= 0 then vars = .;
 end;
run;

ods output DomainQuantiles = out;
proc surveymeans data = MEPS_gt0 median nobs nomcar;
 FORMAT ind ind.;
 VAR &exp_vars.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT11F;
 DOMAIN ind;
run;

proc print data = out;
run;
