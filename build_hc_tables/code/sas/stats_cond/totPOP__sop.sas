* Number of people with care *************************************************;

	/* Sum over persons, conditions */
		proc sort data = all_events;
			by &gp. DUPERSID VARSTR VARPSU PERWT&yy.F Condition ind;
		run;

		proc means data = all_events noprint;
			by &gp. DUPERSID VARSTR VARPSU PERWT&yy.F Condition ind;
			var SF&yy.X MR&yy.X MD&yy.X XP&yy.X PR&yy.X OZ&yy.X;
			output out = all_pers sum = ;
		run;

	/* Remove people with no expenditures */
		data persNA; set all_pers;
			array vars XP&yy.X SF&yy.X MR&yy.X MD&yy.X PR&yy.X OZ&yy.X;
			do over vars;
				if vars <= 0 then vars = 0; else vars = 1;
			end;
		run;

	ods output Domain = out;
	proc surveymeans data = persNA sum ;
		&format.;
		stratum VARSTR;
		cluster VARPSU;
		weight PERWT&yy.F;
		var XP&yy.X SF&yy.X MR&yy.X MD&yy.X PR&yy.X OZ&yy.X;
		domain Condition;
	run;
