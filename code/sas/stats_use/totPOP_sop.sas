%let use_vars = TOTEXP&yy. TOTSLF&yy. TOTPTR&yy. TOTMCR&yy. TOTMCD&yy. TOTOTZ&yy.;

data MEPS_use; set MEPS;
	array vars &use_vars.;
	do over vars;
		vars = (vars > 0);
	end;
run;

ods output Domain = out;
proc surveymeans data = MEPS_use sum missing nobs;
	&format.;
	VAR &use_vars.;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT&yy.F;
	DOMAIN &domain.;
run;

proc print data = out;
run;
