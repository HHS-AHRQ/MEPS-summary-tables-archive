/* Ability to schedule appt. for illness or injury (adults) */
data MEPS; set MEPS;
	adult_illness = ADILWW42;
	domain = (ADILCR42=1 & AGELAST >= 18);
	if domain = 0 and SAQWT&yy.F = 0 then SAQWT&yy.F = 1;
run;

&freq_fmt.

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
	FORMAT adult_illness freq. &fmt.;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT SAQWT&yy.F;
	TABLES domain*&gp.*adult_illness / row;
run;

proc print data = out;
	where domain = 1 and adult_illness ne . &where.;
	var adult_illness &gp. WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
