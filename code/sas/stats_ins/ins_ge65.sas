data MEPS;
	set MEPS;
	domain = (AGELAST >= 65);
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
	&format. insurance_v2X insurance_v2X.;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT&yy.F;
	TABLES domain*&gp.*insurance_v2X / row;
run;

proc print data = out;
	where insurance_v2X ne . ;
	var domain &gp. insurance_v2X Frequency WgtFreq StdDev RowPercent RowStdErr;
run;
