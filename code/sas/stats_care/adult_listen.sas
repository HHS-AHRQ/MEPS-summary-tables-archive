/* How often doctor listened carefully (adults) */
data MEPS; set MEPS;
	adult_listen = ADLIST42;
	domain = (ADAPPT42 >= 1 & AGELAST >= 18);
	if domain = 0 and SAQWT&yy.F = 0 then SAQWT&yy.F = 1;
run;

&freq_fmt.

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
	FORMAT adult_listen freq. &fmt.;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT SAQWT&yy.F;
	TABLES domain*&gp.*adult_listen / row;
run;

proc print data = out;
	where domain = 1 and adult_listen ne . &where.;
	var adult_listen &gp. WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
