/* Children receiving dental care */
data MEPS; set MEPS;
	child_dental = (DVTOT&yy. > 0);
	domain = (1 < AGELAST & AGELAST < 18);
run;

proc format;
	value child_dental
	1 = "One or more dental visits"
	0 = "No dental visits in past year";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
	FORMAT child_dental child_dental. &fmt.;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT&yy.F;
	TABLES domain*&gp.*child_dental / row;
run;

proc print data = out;
	where domain = 1 and child_dental ne . &where.;
	var child_dental &gp. WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
