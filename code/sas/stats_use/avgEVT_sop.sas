data stacked_events;
	set RX DV IP ER OP OB HH;
run;

proc sort data = stacked_events; by DUPERSID; run;
proc sort data = FYCsub; by DUPERSID; run;

data pers_events;
	merge stacked_events FYCsub;
	by DUPERSID;
	EXP = (XP&yy.X > 0);
	SLF = (SF&yy.X > 0);
	MCR = (MR&yy.X > 0);
	MCD = (MD&yy.X > 0);
	PTR = (PR&yy.X > 0);
	OTZ = (OZ&yy.X > 0);
run;

proc means data = pers_events sum noprint;
	by DUPERSID VARSTR VARPSU PERWT&yy.F &gp.;
	var EXP SLF MCR MCD PTR OTZ;
	output out = n_events sum = EXP SLF MCR MCD PTR OTZ;
run;

ods output Domain = out;
proc surveymeans data = n_events mean missing nobs;
	&format.;
	VAR EXP SLF MCR MCD PTR OTZ;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT&yy.F;
	DOMAIN &domain.;
run;

proc print data = out;
run;
