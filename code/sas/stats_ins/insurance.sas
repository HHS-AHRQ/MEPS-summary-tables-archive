ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
	&format. insurance insurance.;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT&yy.F;
	TABLES &gp.*insurance / row;
run;

proc print data = out;
	where insurance ne . ;
	var domain &gp. insurance Frequency WgtFreq StdDev RowPercent RowStdErr;
run;
