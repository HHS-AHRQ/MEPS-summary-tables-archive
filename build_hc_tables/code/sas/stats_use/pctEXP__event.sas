%let exp_vars =
	TOTEXP&yy. DVTEXP&yy. RXEXP&yy.  OBVEXP&yy. OBDEXP&yy.
	OPTEXP&yy. OPYEXP&yy. ERTEXP&yy.
	IPTEXP&yy. HHTEXP&yy. OMAEXP&yy.;

data MEPS_gt0; set MEPS;
	array vars &exp_vars.;
	do over vars;
		vars = (vars > 0);
	end;
run;

ods output Domain = out;
proc surveymeans data = MEPS_gt0 mean missing nobs;
	&format.;
	VAR &exp_vars.;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT&yy.F;
	DOMAIN &domain.;
run;

proc print data = out;
run;
