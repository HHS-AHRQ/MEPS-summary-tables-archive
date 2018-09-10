/* How often doctor explained things (children) */
data MEPS; set MEPS;
	child_explain = CHEXPL42;
	domain = (CHAPPT42 >= 1 & AGELAST < 18);
run;

&freq_fmt.

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
	FORMAT child_explain freq. &fmt.;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT&yy.F;
	TABLES domain*&gp.*child_explain / row;
run;

proc print data = out;
	where domain = 1 and child_explain ne . &where.;
	var child_explain &gp. WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
