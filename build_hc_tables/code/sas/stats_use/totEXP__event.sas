%let exp_vars =
	TOTEXP&yy. DVTEXP&yy. RXEXP&yy.  OBVEXP&yy. OBDEXP&yy.
	OPTEXP&yy. OPYEXP&yy. ERTEXP&yy.
	IPTEXP&yy. HHTEXP&yy. OMAEXP&yy.;

ods output Domain = out;
proc surveymeans data = MEPS sum missing nobs;
	&format.;
	VAR &exp_vars.;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT&yy.F;
	DOMAIN &domain.;
run;

proc print data = out;
run;
