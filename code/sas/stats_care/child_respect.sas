/* How often doctor showed respect (children) */
data MEPS; set MEPS;
	child_respect = CHRESP42;
	domain = (CHAPPT42 >= 1 & AGELAST < 18);
run;

&freq_fmt.

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
	FORMAT child_respect freq. &fmt.;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT&yy.F;
	TABLES domain*&gp.*child_respect / row;
run;

proc print data = out;
	where domain = 1 and child_respect ne . &where.;
	var child_respect &gp. WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
