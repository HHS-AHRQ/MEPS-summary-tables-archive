%let exp_vars =
	TOTEXP&yy. DVTEXP&yy. RXEXP&yy.  OBVEXP&yy. OBDEXP&yy.
	OBOEXP&yy. OPTEXP&yy. OPYEXP&yy. OPZEXP&yy. ERTEXP&yy.
	IPTEXP&yy. HHTEXP&yy. OMAEXP&yy.;

data MEPS_gt0; set MEPS;
	array vars &exp_vars.;
	do over vars;
		if vars <= 0 then vars = .;
	end;
run;

ods output DomainQuantiles = out;
proc surveymeans data = MEPS_gt0 median nobs nomcar;
	&format.;
	VAR &exp_vars.;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT&yy.F;
	DOMAIN &domain.;
run;

proc print data = out;
run;
