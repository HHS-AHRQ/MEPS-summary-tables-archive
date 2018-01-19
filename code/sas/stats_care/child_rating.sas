/* Rating for care (children) */
data MEPS; set MEPS;
	child_rating = CHHECR42;
	domain = (CHAPPT42 >= 1 & AGELAST < 18);
run;

proc format;
	value child_rating
	9-10 = "9-10 rating"
	7-8 = "7-8 rating"
	0-6 = "0-6 rating"
	-9 - -7 = "Don't know/Non-response"
	-1 = "Inapplicable";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
	FORMAT child_rating child_rating. &fmt.;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT&yy.F;
	TABLES domain*&gp.*child_rating / row;
run;

proc print data = out;
	where domain = 1 and child_rating ne . &where.;
	var child_rating &gp. WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
