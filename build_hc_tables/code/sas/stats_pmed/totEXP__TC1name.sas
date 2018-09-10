&tc1_fmt.;

ods output Domain = out;
proc surveymeans data = RX sum;
	format TC1 TC1name.;
	stratum VARSTR;
	cluster VARPSU;
	weight PERWT&yy.F;
	var RXXP&yy.X;
	domain TC1;
run;

proc print data = out;
run;
