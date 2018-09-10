* Total number of events ************************************************;

	ods output Domain = out;
	proc surveymeans data = all_events sum ;
		&format.;
		stratum VARSTR;
		cluster VARPSU;
		weight PERWT&yy.F;
		var n_XP n_SF n_MR n_MD n_PR n_OZ ;
		domain Condition;
	run;
