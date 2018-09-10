data EVENTS_ge0; set EVENTS;
	if XP&yy.X < 0 then XP&yy.X = .;
run;

ods output Domain = out;
proc surveymeans data = EVENTS_ge0 mean missing nobs;
	&format.;
	VAR XP&yy.X;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT&yy.F;
	DOMAIN &domain.*event;
run;

proc print data = out;
run;
