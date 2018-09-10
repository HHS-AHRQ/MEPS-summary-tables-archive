/* Marital Status */
	data MEPS; set MEPS;
		ARRAY OLDMAR(2) MARRY1X MARRY2X;
		if year = 1996 then do;
			if MARRY2X <= 6 then MARRY42X = MARRY2X;
			else MARRY42X = MARRY2X-6;

			if MARRY1X <= 6 then MARRY31X = MARRY1X;
			else MARRY31X = MARRY1X-6;
		end;

		if MARRY&yy.X >= 0 then married = MARRY&yy.X;
		else if MARRY42X >= 0 then married = MARRY42X;
		else if MARRY31X >= 0 then married = MARRY31X;
		else married = .;
	run;

	proc format;
		value married
		1 = "Married"
		2 = "Widowed"
		3 = "Divorced"
		4 = "Separated"
		5 = "Never married"
		6 = "Inapplicable (age < 16)"
		. = "Missing";
	run;
