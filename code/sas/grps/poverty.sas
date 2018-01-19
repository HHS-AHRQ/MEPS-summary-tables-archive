/* Poverty status */
data MEPS; set MEPS;
	ARRAY OLDPOV(1) POVCAT;
	if year = 1996 then POVCAT96 = POVCAT;
	poverty = POVCAT&yy.;
run;

proc format;
	value poverty
	1 = "Negative or poor"
	2 = "Near-poor"
	3 = "Low income"
	4 = "Middle income"
	5 = "High income";
run;
