data EVENTS_ge0; set EVENTS;
	XP&yy.X = (XP&yy.X >= 0);
run;

ods output Domain = out;
proc surveymeans data = EVENTS_ge0 sum missing nobs;
	&format.;
	VAR XP&yy.X;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT&yy.F;
	DOMAIN &domain.;
run;

proc print data = out;
run;
