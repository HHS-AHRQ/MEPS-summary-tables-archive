proc sort data = all_events;
	by &gp. DUPERSID VARSTR VARPSU PERWT&yy.F Condition ind count;
run;

proc means data = all_events noprint;
	by &gp. DUPERSID VARSTR VARPSU PERWT&yy.F Condition ind count;
	var SF&yy.X MR&yy.X MD&yy.X XP&yy.X PR&yy.X OZ&yy.X;
	output out = all_pers sum = ;
run;

ods output Domain = out;
proc surveymeans data = all_pers mean ;
	&format.;
	stratum VARSTR;
	cluster VARPSU;
	weight PERWT&yy.F;
	var XP&yy.X;
	domain Condition*&gp. ;
run;
