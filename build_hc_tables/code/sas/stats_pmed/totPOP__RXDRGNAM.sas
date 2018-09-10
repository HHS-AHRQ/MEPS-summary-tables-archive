proc sort data = RX;
	by DUPERSID VARSTR VARPSU PERWT&yy.F RXDRGNAM;
run;

proc means data = RX noprint;
	where domain = 1;
	by DUPERSID VARSTR VARPSU PERWT&yy.F RXDRGNAM;
	var count;
	output out = DRGpers mean = ind;
run;

ods output Domain = out;
proc surveymeans data = DRGpers sum ;
	stratum VARSTR;
	cluster VARPSU;
	weight PERWT&yy.F;
	var ind;
	domain RXDRGNAM;
run;

proc print data = out;
run;
