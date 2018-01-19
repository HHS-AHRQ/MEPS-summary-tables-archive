proc sort data = stacked_events; by DUPERSID; run;
proc sort data = FYCsub; by DUPERSID; run;

data EVENTS;
	merge stacked_events FYCsub;
	by DUPERSID;
run;
