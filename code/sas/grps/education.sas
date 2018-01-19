/* Education */
data MEPS; set MEPS;
	ARRAY EDUVARS(4) EDUCYR&yy. EDUCYR EDUCYEAR EDRECODE;
	if year <= 1998 then EDUCYR = EDUCYR&yy.;
	else if year <= 2004 then EDUCYR = EDUCYEAR;

	if year >= 2012 then do;
		less_than_hs = (0 <= EDRECODE and EDRECODE < 13);
		high_school  = (EDRECODE = 13);
		some_college = (EDRECODE > 13);
	end;

	else do;
		less_than_hs = (0 <= EDUCYR and EDUCYR < 12);
		high_school  = (EDUCYR = 12);
		some_college = (EDUCYR > 12);
	end;

	education = 1*less_than_hs + 2*high_school + 3*some_college;

	if AGELAST < 18 then education = 9;
run;

proc format;
	value education
	1 = "Less than high school"
	2 = "High school"
	3 = "Some college"
	9 = "Inapplicable (age < 18)"
	0 = "Missing"
	. = "Missing";
run;
