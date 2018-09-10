* Total expenditures ********************************************************;

	ods output Domain = out;
	proc surveymeans data = all_events sum ;
		&format.;
		stratum VARSTR;
		cluster VARPSU;
		weight PERWT&yy.F;
		var XP&yy.X;
		domain Condition*&gp. ;
	run;
