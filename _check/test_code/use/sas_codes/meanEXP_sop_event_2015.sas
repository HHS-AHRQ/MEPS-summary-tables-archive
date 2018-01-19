ods graphics off;

/* Read in dataset and initialize year */
FILENAME h181 "C:\MEPS\h181.ssp";
proc xcopy in = h181 out = WORK IMPORT;
run;

data MEPS;
 SET h181;
 ARRAY OLDVAR(5) VARPSU15 VARSTR15 WTDPER15 AGE2X AGE1X;
 year = 2015;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU15;
  VARSTR = VARSTR15;
 end;

 if year <= 1998 then do;
  PERWT15F = WTDPER15;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE15X >= 0 then AGELAST = AGE15x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Event type and source of payment */
%macro add_sops(event);
 if year <= 1999 then do;
  &event.TRI15 = &event.CHM15;
 end;

 &event.OTH15 = &event.OFD15 + &event.STL15 + &event.OPR15 + &event.OPU15 + &event.OSR15;
 &event.OTZ15 = &event.OTH15 + &event.WCP15 + &event.VA15;
 &event.PTR15 = &event.PRV15 + &event.TRI15;
%mend;

%macro add_events(sop);
 HHT&sop.15 = HHA&sop.15 + HHN&sop.15; /* Home Health Agency + Independent providers */
 ERT&sop.15 = ERF&sop.15 + ERD&sop.15; /* Doctor + Facility expenses for OP, ER, IP events */
 IPT&sop.15 = IPF&sop.15 + IPD&sop.15;
 OPT&sop.15 = OPF&sop.15 + OPD&sop.15; /* All Outpatient */
 OPY&sop.15 = OPV&sop.15 + OPS&sop.15; /* Physician only */
 OPZ&sop.15 = OPO&sop.15 + OPP&sop.15; /* Non-physician only */
 OMA&sop.15 = VIS&sop.15 + OTH&sop.15;
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
 TOTEXP15 DVTEXP15 RXEXP15  OBVEXP15 OBDEXP15
 OBOEXP15 OPTEXP15 OPYEXP15 OPZEXP15 ERTEXP15
 IPTEXP15 HHTEXP15 OMAEXP15

 TOTSLF15 DVTSLF15 RXSLF15  OBVSLF15 OBDSLF15
 OBOSLF15 OPTSLF15 OPYSLF15 OPZSLF15 ERTSLF15
 IPTSLF15 HHTSLF15 OMASLF15

 TOTPTR15 DVTPTR15 RXPTR15  OBVPTR15 OBDPTR15
 OBOPTR15 OPTPTR15 OPYPTR15 OPZPTR15 ERTPTR15
 IPTPTR15 HHTPTR15 OMAPTR15

 TOTMCR15 DVTMCR15 RXMCR15 OBVMCR15 OBDMCR15
 OBOMCR15 OPTMCR15 OPYMCR15 OPZMCR15 ERTMCR15
 IPTMCR15 HHTMCR15 OMAMCR15

 TOTMCD15 DVTMCD15 RXMCD15  OBVMCD15 OBDMCD15
 OBOMCD15 OPTMCD15 OPYMCD15 OPZMCD15 ERTMCD15
 IPTMCD15 HHTMCD15 OMAMCD15

 TOTOTZ15 DVTOTZ15 RXOTZ15  OBVOTZ15 OBDOTZ15
 OBOOTZ15 OPTOTZ15 OPYOTZ15 OPZOTZ15 ERTOTZ15
 IPTOTZ15 HHTOTZ15 OMAOTZ15;

data MEPS_gt0; set MEPS;
 array vars &exp_vars.;
 do over vars;
  if vars <= 0 then vars = .;
 end;
run;

ods output Domain = out;
proc surveymeans data = MEPS_gt0 mean nobs nomcar;
 FORMAT ind ind.;
 VAR &exp_vars.;
 STRATA VARSTR;
 CLUSTER VARPSU;
 WEIGHT PERWT15F;
 DOMAIN ind;
run;

proc print data = out;
run;
