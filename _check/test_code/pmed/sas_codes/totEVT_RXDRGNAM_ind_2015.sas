ods graphics off;

/* Read in dataset and initialize year */

FILENAME h178a "C:\MEPS\h178a.ssp";
proc xcopy in = h178a out = WORK IMPORT;
run;

data RX;
 set &syslast; 
 ARRAY OLDVAR(3) VARPSU15 VARSTR15 WTDPER15;
 year = 2015;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU15;
  VARSTR = VARSTR15;
 end;

 if year <= 1998 then do;
  PERWT15F = WTDPER15;
 end;

 domain = (RXNDC ne "-9");
run;

ods output Domain = out;
proc surveymeans data = RX sum ;
 stratum VARSTR;
 cluster VARPSU;
 weight PERWT15F;
 var count;
 domain domain*RXDRGNAM;
run;

proc print data = out;
 where domain = 1;
run;
