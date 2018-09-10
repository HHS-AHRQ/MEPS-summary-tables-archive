/* How often doctor spent enough time (children) */
data MEPS; set MEPS;
	child_time = CHPRTM42;
	domain = (CHAPPT42 >= 1 & AGELAST < 18);
run;

&freq_fmt.

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
	FORMAT child_time freq. &fmt.;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT&yy.F;
	TABLES domain*&gp.*child_time / row;
run;

proc print data = out;
	where domain = 1 and child_time ne . &where.;
	var child_time &gp. WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
