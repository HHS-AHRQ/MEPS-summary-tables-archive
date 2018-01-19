/* How often doctor spent enough time (adults) */
data MEPS; set MEPS;
	adult_time = ADPRTM42;
	domain = (ADAPPT42 >= 1 & AGELAST >= 18);
	if domain = 0 and SAQWT&yy.F = 0 then SAQWT&yy.F = 1;
run;

&freq_fmt.

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
	FORMAT adult_time freq. &fmt.;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT SAQWT&yy.F;
	TABLES domain*&gp.*adult_time / row;
run;

proc print data = out;
	where domain = 1 and adult_time ne . &where.;
	var adult_time &gp. WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
