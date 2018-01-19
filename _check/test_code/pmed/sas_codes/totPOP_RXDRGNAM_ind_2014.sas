ods graphics off;

/* Read in dataset and initialize year */

FILENAME h168a "C:\MEPS\h168a.ssp";
proc xcopy in = h168a out = WORK IMPORT;
run;

data RX;
 set &syslast; 
 ARRAY OLDVAR(3) VARPSU14 VARSTR14 WTDPER14;
 year = 2014;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU14;
  VARSTR = VARSTR14;
 end;

 if year <= 1998 then do;
  PERWT14F = WTDPER14;
 end;

 domain = (RXNDC ne "-9");
run;

proc sort data = RX;
 by DUPERSID VARSTR VARPSU PERWT14F RXDRGNAM;
run;

proc means data = RX noprint;
 where domain = 1;
 by DUPERSID VARSTR VARPSU PERWT14F RXDRGNAM;
 var count;
 output out = DRGpers mean = ind;
run;

ods output Domain = out;
proc surveymeans data = DRGpers sum ;
 stratum VARSTR;
 cluster VARPSU;
 weight PERWT14F;
 var ind;
 domain RXDRGNAM;
run;

proc print data = out;
run;
