ods output Domain = out;
proc surveymeans data = MEPS sum missing nobs;
	&format.;
	VAR TOTEXP&yy.;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT&yy.F;
	DOMAIN &domain.;
run;

proc print data = out;
run;
