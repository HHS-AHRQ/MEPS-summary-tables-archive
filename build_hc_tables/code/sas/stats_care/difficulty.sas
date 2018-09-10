/* Difficulty receiving needed care */
data MEPS; set MEPS;
	delay_MD = (MDUNAB42 = 1|MDDLAY42=1);
	delay_DN = (DNUNAB42 = 1|DNDLAY42=1);
	delay_PM = (PMUNAB42 = 1|PMDLAY42=1);
	delay_ANY = (delay_MD|delay_DN|delay_PM);
	domain = (ACCELI42 = 1);
run;

proc format;
	value delay
	1 = "Difficulty accessing care"
	0 = "No difficulty";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
	FORMAT delay: delay. &fmt.;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT&yy.F;
	TABLES domain*&gp.*(delay_ANY delay_MD delay_DN delay_PM) / row;
run;

proc print data = out;
	where domain = 1 and (delay_ANY > 0 or delay_MD > 0 or delay_DN > 0 or delay_PM > 0) &where.;
	var delay_ANY delay_MD delay_DN delay_PM &gp. WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
