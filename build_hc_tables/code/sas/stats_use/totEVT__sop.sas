data EVENTS_ge0; set EVENTS;
	array vars XP&yy.X SF&yy.X PR&yy.X MR&yy.X MD&yy.X OZ&yy.X;
	do over vars;
		vars = (vars > 0);
	end;
run;

ods output Domain = out;
proc surveymeans data = EVENTS_ge0 sum missing nobs;
	&format.;
	VAR XP&yy.X SF&yy.X PR&yy.X MR&yy.X MD&yy.X OZ&yy.X;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT&yy.F;
	DOMAIN &domain.;
run;

proc print data = out;
run;
