data MEPS_gt0; set MEPS;
	if TOTEXP&yy. <= 0 then TOTEXP&yy. = .;
run;

ods output Domain = out;
proc surveymeans data = MEPS_gt0 mean nobs nomcar;
	&format.;
	VAR TOTEXP&yy.;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT&yy.F;
	DOMAIN &domain.;
run;

proc print data = out;
run;
