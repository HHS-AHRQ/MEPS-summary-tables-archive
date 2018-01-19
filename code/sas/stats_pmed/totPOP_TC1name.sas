proc sort data = RX;
	by DUPERSID VARSTR VARPSU PERWT&yy.F TC1;
run;

proc means data = RX noprint;
	by DUPERSID VARSTR VARPSU PERWT&yy.F TC1;
	var count;
	output out = TC1pers mean = ind;
run;

&tc1_fmt.;

ods output Domain = out;
proc surveymeans data = TC1pers sum ;
	format TC1 TC1name.;
	stratum VARSTR;
	cluster VARPSU;
	weight PERWT&yy.F;
	var ind;
	domain TC1;
run;

proc print data = out;
run;
