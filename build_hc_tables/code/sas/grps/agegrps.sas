/* Age groups */
/* To compute for additional age groups, replace 'agegrps' in the SURVEY procedure with 'agegrps_v2X'  */
	data MEPS; set MEPS;
		agegrps = AGELAST;
		agegrps_v2X = AGELAST;
		agegrps_v3X = AGELAST;
	run;

	proc format;
		value agegrps
		low-4 = "Under 5"
		5-17  = "5-17"
		18-44 = "18-44"
		45-64 = "45-64"
		65-high = "65+";

		value agegrps_v2X
		low-17  = "Under 18"
		18-64   = "18-64"
		65-high = "65+";

		value agegrps_v3X
		low-4 = "Under 5"
		5-6   = "5-6"
		7-12  = "7-12"
		13-17 = "13-17"
		18    = "18"
		19-24 = "19-24"
		25-29 = "25-29"
		30-34 = "30-34"
		35-44 = "35-44"
		45-54 = "45-54"
		55-64 = "55-64"
		65-high = "65+";
	run;
