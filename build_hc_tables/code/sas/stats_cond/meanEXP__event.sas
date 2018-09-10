* Mean expenditure per person ************************************************;

	/* Sum expenditures by person, event */
		proc sort data = all_events;
			by &gp. DUPERSID VARSTR VARPSU PERWT&yy.F Condition event ind;
		run;

		proc means data = all_events noprint;
			by &gp. DUPERSID VARSTR VARPSU PERWT&yy.F Condition event ind;
			var SF&yy.X MR&yy.X MD&yy.X XP&yy.X PR&yy.X OZ&yy.X;
			output out = all_persev sum = ;
		run;

	ods output Domain = out;
	proc surveymeans data = all_persev mean ;
		&format.;
		stratum VARSTR;
		cluster VARPSU;
		weight PERWT&yy.F;
		var XP&yy.X;
		domain Condition*event ;
	run;
