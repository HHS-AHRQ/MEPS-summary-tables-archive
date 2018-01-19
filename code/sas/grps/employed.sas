/* Employment Status */
data MEPS; set MEPS;
	ARRAY OLDEMP(3) EMPST1 EMPST2 EMPST96;
	if year = 1996 then do;
		EMPST53 = EMPST96;
		EMPST42 = EMPST2;
		EMPST31 = EMPST1;
	end;

	if EMPST53 >= 0 then employ_last = EMPST53;
	else if EMPST42 >= 0 then employ_last = EMPST42;
	else if EMPST31 >= 0 then employ_last = EMPST31;
	else employ_last = .;

	employed = 1*(employ_last = 1) + 2*(employ_last > 1);
	if employed < 1 and AGELAST < 16 then employed = 9;
run;

proc format;
	value employed
	1 = "Employed"
	2 = "Not employed"
	9 = "Inapplicable (age < 16)"
	. = "Missing"
	0 = "Missing";
run;
