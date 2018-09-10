* Load and stack event files *************************************************;

/* Load event files */
	%load_events(RX,&RX.);
	%load_events(IP,&IP.);
	%load_events(ER,&ER.);
	%load_events(OP,&OP.);
	%load_events(OB,&OB.);
	%load_events(HH,&HH.);

/* Stack events */
	data RX; set RX;
		EVNTIDX = LINKIDX;
	run;

	data stacked_events;
		set RX IP ER OP OB HH;
		where XP&yy.X >= 0;
		count = 1;
		n_XP = (XP&yy.X > 0);
		n_SF = (SF&yy.X > 0);
		n_MR = (MR&yy.X > 0);
		n_MD = (MD&yy.X > 0);
		n_PR = (PR&yy.X > 0);
		n_OZ = (OZ&yy.X > 0);
	run;

* Read and merge conditions-CLINK files **************************************;

/* Read in event-condition linking file */
	FILENAME &CLNK. "C:\MEPS\&CLNK..ssp";
	proc xcopy in = &CLNK. out = WORK IMPORT; run;
	data clink1;
		set &syslast;
		keep DUPERSID CONDIDX EVNTIDX;
	run;

/* Read in conditions file */
	FILENAME &Conditions. "C:\MEPS\&Conditions..ssp";
	proc xcopy in = &Conditions. out = WORK IMPORT; run;
	data Conditions;
		set &syslast;
		keep DUPERSID CONDIDX CCCODEX condition;
		CCS_code = CCCODEX*1;
		condition = PUT(CCS_code, CCCFMT.);
	run;

/* Merge Conditions and CLINK files */
	proc sort data = clink1; by DUPERSID CONDIDX; run;
	proc sort data = conditions; by DUPERSID CONDIDX; run;
	data cond;
		merge clink1 conditions;
		by DUPERSID CONDIDX;
	run;

* Merge stacked events with Conditions file **********************************;

/* Count events for each EVNTIDX (can have multiple RX) */
/* A single EVNTIDX row is needed for correct merging   */
	proc sort data = stacked_events; by event DUPERSID EVNTIDX; run;
	proc means data = stacked_events noprint;
		by event DUPERSID EVNTIDX;
		var count SF&yy.X MR&yy.X MD&yy.X XP&yy.X PR&yy.X OZ&yy.X n_: ;
		output out = n_events sum = ;
	run;

/* Merge n_events with Conditions-CLINK file */
	proc sort data = cond nodupkey; by DUPERSID EVNTIDX condition; run;
	proc sort data = n_events; by DUPERSID EVNTIDX; run;
	data event_cond;
		merge n_events cond;
		by DUPERSID EVNTIDX;
		if condition in ("-1","-9","") or XP&yy.X < 0 then delete;
	run;

* Merge with FYC file ********************************************************;
	data FYCsub; set MEPS;
		keep &gp. DUPERSID PERWT&yy.F VARSTR VARPSU;
	run;

	proc sort data = FYCsub; by DUPERSID; run;
	data all_events;
		merge event_cond FYCsub;
		by DUPERSID;
		ind = 1;
	run;
