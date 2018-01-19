ods output Domain = out;
proc surveymeans data = all_events sum ;
	&format.;
	stratum VARSTR;
	cluster VARPSU;
	weight PERWT&yy.F;
	var count;
	domain Condition*&gp. ;
run;
