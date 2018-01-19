/* Census Region */
data MEPS; set MEPS;
	ARRAY OLDREG(2) REGION1 REGION2;
	if year = 1996 then do;
		REGION42 = REGION2;
		REGION31 = REGION1;
	end;

	if REGION&yy. >= 0 then region = REGION&yy.;
	else if REGION42 >= 0 then region = REGION42;
	else if REGION31 >= 0 then region = REGION31;
	else region = .;
run;

proc format;
	value region
	1 = "Northeast"
	2 = "Midwest"
	3 = "South"
	4 = "West"
	. = "Missing";
run;
