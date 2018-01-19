ods graphics off;

/* Read in dataset and initialize year */
FILENAME &FYC. "&PUFdir.\&FYC..ssp";
proc xcopy in = &FYC. out = WORK IMPORT;
run;

data MEPS;
	SET &FYC.;
	year = &year.;
	ind = 1;
	count = 1;

	/* Create AGELAST variable */
	if AGE&yy.X >= 0 then AGELAST=AGE&yy.x;
	else if AGE42X >= 0 then AGELAST=AGE42X;
	else if AGE31X >= 0 then AGELAST=AGE31X;
run;

proc format;
	value ind 1 = "Total";
run;
