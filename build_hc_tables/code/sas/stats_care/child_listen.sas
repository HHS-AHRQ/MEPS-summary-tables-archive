/* How often doctor listened carefully (children) */
data MEPS; set MEPS;
	child_listen = CHLIST42;
	domain = (CHAPPT42 >= 1 & AGELAST < 18);
run;

&freq_fmt.

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
	FORMAT child_listen freq. &fmt.;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT&yy.F;
	TABLES domain*&gp.*child_listen / row;
run;

proc print data = out;
	where domain = 1 and child_listen ne . &where.;
	var child_listen &gp. WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
