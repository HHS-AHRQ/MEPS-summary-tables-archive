ods graphics off;

/* Read in dataset and initialize year */

FILENAME h160a "C:\MEPS\h160a.ssp";
proc xcopy in = h160a out = WORK IMPORT;
run;

data RX;
 set &syslast; 
 ARRAY OLDVAR(3) VARPSU13 VARSTR13 WTDPER13;
 year = 2013;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU13;
  VARSTR = VARSTR13;
 end;

 if year <= 1998 then do;
  PERWT13F = WTDPER13;
 end;

 domain = (RXNDC ne "-9");
run;

ods output Domain = out;
proc surveymeans data = RX sum ;
 stratum VARSTR;
 cluster VARPSU;
 weight PERWT13F;
 var count;
 domain domain*RXDRGNAM;
run;

proc print data = out;
 where domain = 1;
run;
