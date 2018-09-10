data EVENTS_ge0; set EVENTS;
	array vars XP&yy.X SF&yy.X PR&yy.X MR&yy.X MD&yy.X OZ&yy.X;
	do over vars;
		if vars < 0 then vars = .;
	end;
run;

ods output Domain = out;
proc surveymeans data = EVENTS_ge0 mean missing nobs;
	&format.;
	VAR XP&yy.X SF&yy.X PR&yy.X MR&yy.X MD&yy.X OZ&yy.X;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT&yy.F;
	DOMAIN &domain.;
run;

proc print data = out;
run;
