%macro avgEVT(event);

	proc sort data = &event.; by DUPERSID; run;
	proc sort data = FYCsub; by DUPERSID; run;

	data pers_events;
		merge &event. FYCsub;
		by DUPERSID;
		EXP = (XP&yy.X >= 0);
	run;

	proc means data = pers_events sum noprint;
		by DUPERSID VARSTR VARPSU PERWT&yy.F &gp. ;
		var EXP;
		output out = n_events sum = EXP;
	run;

	title "Event = &event";
	ods output Domain = out_&event;
	proc surveymeans data = n_events mean missing nobs;
		&format.;
		VAR EXP;
		STRATA VARSTR;
		CLUSTER VARPSU;
		WEIGHT PERWT&yy.F;
		DOMAIN &domain.;
	run;
%mend;

data OBD OBO;
	set OB;
	if event_v2X = 'OBD' then output OBD;
	if event_v2X = 'OBO' then output OBO;
run;

data OPY OPZ;
	set OP;
	if event_v2X = 'OPY' then output OPY;
	if event_v2X = 'OPZ' then output OPZ;
run;

%avgEVT(RX);
%avgEVT(DV);
%avgEVT(IP);
%avgEVT(ER);
%avgEVT(HH);

%avgEVT(OP);
  %avgEVT(OPY);
  %avgEVT(OPZ);

%avgEVT(OB);
  %avgEVT(OBD);
  %avgEVT(OBO);
