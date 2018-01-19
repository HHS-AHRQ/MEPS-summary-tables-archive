/* Reason for difficulty receiving needed prescribed medicines */
data MEPS; set MEPS;
	delay_PM  = (PMUNAB42=1|PMDLAY42=1);
	afford_PM = (PMDLRS42=1|PMUNRS42=1);
	insure_PM = (PMDLRS42 in (2,3)|PMUNRS42 in (2,3));
	other_PM  = (PMDLRS42 > 3|PMUNRS42 > 3);
	domain = (ACCELI42 = 1 & delay_PM=1);
run;

proc format;
	value afford 1 = "Couldn't afford";
	value insure 1 = "Insurance related";
	value other 1 = "Other";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
	FORMAT afford_PM afford. insure_PM insure. other_PM other. &fmt.;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT&yy.F;
	TABLES domain*&gp.*(afford_PM insure_PM other_PM) / row;
run;

proc print data = out;
	where domain = 1 and (afford_PM > 0 or insure_PM > 0 or other_PM > 0) &where.;
	var afford_PM insure_PM other_PM &gp. WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
