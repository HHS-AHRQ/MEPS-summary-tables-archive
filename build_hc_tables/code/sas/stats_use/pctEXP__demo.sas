data MEPS_gt0; set MEPS;
		TOTEXP&yy. = (TOTEXP&yy. > 0);
run;

ods output Domain = out;
proc surveymeans data = MEPS_gt0 mean missing nobs;
	&format.;
	VAR TOTEXP&yy.;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT&yy.F;
	DOMAIN &domain.;
run;

proc print data = out;
run;
