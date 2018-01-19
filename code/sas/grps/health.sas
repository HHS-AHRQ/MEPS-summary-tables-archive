/* Perceived health status */
data MEPS; set MEPS;
	ARRAY OLDHLT(2) RTEHLTH1 RTEHLTH2;
	if year = 1996 then do;
		RTHLTH53 = RTEHLTH2;
		RTHLTH42 = RTEHLTH2;
		RTHLTH31 = RTEHLTH1;
	end;

	if RTHLTH53 >= 0 then health = RTHLTH53;
	else if RTHLTH42 >= 0 then health = RTHLTH42;
	else if RTHLTH31 >= 0 then health = RTHLTH31;
	else health = .;
run;

proc format;
	value health
	1 = "Excellent"
	2 = "Very good"
	3 = "Good"
	4 = "Fair"
	5 = "Poor"
	. = "Missing";
run;
