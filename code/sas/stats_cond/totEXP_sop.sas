ods output Domain = out;
proc surveymeans data = all_events sum ;
	&format.;
	stratum VARSTR;
	cluster VARPSU;
	weight PERWT&yy.F;
	var XP&yy.X SF&yy.X MR&yy.X MD&yy.X PR&yy.X OZ&yy.X;
	domain Condition;
run;
