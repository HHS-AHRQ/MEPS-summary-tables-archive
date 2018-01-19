&cond_format.

data RX;
	set RX;
	EVNTIDX = LINKIDX;
run;

/* Sum RX purchases for each event */
proc sort data = RX; by event DUPERSID EVNTIDX; run;
proc means data = RX noprint;
	by event DUPERSID EVNTIDX;
	var SF&yy.X MR&yy.X MD&yy.X XP&yy.X PR&yy.X OZ&yy.X;
	output out = RXpers sum = ;
run;

data stacked_events;
	set RXpers IP ER OP OB HH;
	where XP&yy.X >= 0;
	count = 1;
	ind = 1;
run;

/* Read in event-condition linking file */
FILENAME &CLNK. "C:\MEPS\&CLNK..ssp";
proc xcopy in = &CLNK. out = WORK IMPORT; run;
data clink1;
	set &syslast;
	keep DUPERSID CONDIDX EVNTIDX;
run;

FILENAME &Conditions. "C:\MEPS\&Conditions..ssp";
proc xcopy in = &Conditions. out = WORK IMPORT; run;
data Conditions;
	set &syslast;
	keep DUPERSID CONDIDX CCCODEX condition;
	CCS_code = CCCODEX*1;
	condition = PUT(CCS_code, CCCFMT.);
run;

proc sort data = clink1; by DUPERSID CONDIDX; run;
proc sort data = conditions; by DUPERSID CONDIDX; run;
data cond;
	merge clink1 conditions;
	by DUPERSID CONDIDX;
run;

proc sort data = cond nodupkey; by DUPERSID EVNTIDX condition; run;
proc sort data = stacked_events; by DUPERSID EVNTIDX; run;
data event_cond;
	merge stacked_events cond;
	by DUPERSID EVNTIDX;
	if condition in ("-1","-9","") or XP&yy.X < 0 then delete;
run;

proc sort data = FYCsub; by DUPERSID; run;
data all_events;
	merge event_cond FYCsub;
	by DUPERSID;
	count = 1;
	ind = 1;
run;
