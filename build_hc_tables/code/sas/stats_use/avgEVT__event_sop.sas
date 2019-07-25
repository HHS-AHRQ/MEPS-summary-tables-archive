%macro avgEVT(event);

	proc sort data = &event.; by DUPERSID; run;
	proc sort data = FYCsub; by DUPERSID; run;

	data pers_events;
		merge &event. FYCsub;
		by DUPERSID;
		EXP = (XP&yy.X > 0);
		SLF = (SF&yy.X > 0);
		MCR = (MR&yy.X > 0);
		MCD = (MD&yy.X > 0);
		PTR = (PR&yy.X > 0);
		OTZ = (OZ&yy.X > 0);
	run;

	proc means data = pers_events sum noprint;
		by DUPERSID VARSTR VARPSU PERWT&yy.F &gp. ;
		var EXP SLF MCR MCD PTR OTZ;
		output out = n_events sum = EXP SLF MCR MCD PTR OTZ;
	run;

	title "Event = &event";
	ods output Domain = out_&event;
	proc surveymeans data = n_events mean missing nobs;
		&format.;
		var EXP SLF MCR MCD PTR OTZ;
		STRATA VARSTR;
		CLUSTER VARPSU;
		WEIGHT PERWT&yy.F;
		DOMAIN &domain.;
	run;
%mend;

data OBD;
	set OB;
	if event_v2X = 'OBD' then output OBD;
run;

data OPY;
	set OP;
	if event_v2X = 'OPY' then output OPY;
run;

%avgEVT(RX);
%avgEVT(DV);
%avgEVT(IP);
%avgEVT(ER);
%avgEVT(HH);

%avgEVT(OP);
  %avgEVT(OPY);

%avgEVT(OB);
  %avgEVT(OBD);
