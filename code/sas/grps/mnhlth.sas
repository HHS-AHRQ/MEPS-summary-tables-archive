/* Perceived mental health */
data MEPS; set MEPS;
	ARRAY OLDMNH(2) MNTHLTH1 MNTHLTH2;
	if year = 1996 then do;
		MNHLTH53 = MNTHLTH2;
		MNHLTH42 = MNTHLTH2;
		MNHLTH31 = MNTHLTH1;
	end;

	if MNHLTH53 ge 0 then mnhlth = MNHLTH53;
	else if MNHLTH42 ge 0 then mnhlth = MNHLTH42;
	else if MNHLTH31 ge 0 then mnhlth = MNHLTH31;
	else mnhlth = .;
run;

proc format;
	value mnhlth
	1 = "Excellent"
	2 = "Very good"
	3 = "Good"
	4 = "Fair"
	5 = "Poor"
	. = "Missing";
run;
