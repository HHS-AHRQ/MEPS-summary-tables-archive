data stacked_events;
	set RX DV IP ER OP OB HH;
run;

proc sort data = stacked_events; by DUPERSID; run;
proc sort data = FYCsub; by DUPERSID; run;

data pers_events;
	merge stacked_events FYCsub;
	by DUPERSID;
	EXP = (XP&yy.X >= 0);
run;

proc means data = pers_events sum noprint;
	by DUPERSID VARSTR VARPSU PERWT&yy.F &gp. ;
	var EXP;
	output out = n_events sum = EXP;
run;

ods output Domain = out;
proc surveymeans data = n_events mean missing nobs;
	&format.;
	VAR EXP;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT&yy.F;
	DOMAIN &domain.;
run;

proc print data = out;
run;
