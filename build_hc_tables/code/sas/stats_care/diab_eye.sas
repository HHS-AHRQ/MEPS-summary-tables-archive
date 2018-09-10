/* Diabetes care: Eye exam */
data MEPS; set MEPS;

	past_year = (DSEY&yy.53=1 | DSEY&ya.53=1);
	more_year = (DSEY&yb.53=1 | DSEB&yb.53=1);
	never_chk = (DSEYNV53 = 1);
	non_resp = (DSEY&yy.53 in (-7,-8,-9));

	if past_year = 1 then diab_eye = 1;
	else if more_year = 1 then diab_eye = 2;
	else if never_chk = 1 then diab_eye = 3;
	else if non_resp = 1  then diab_eye = -7;
	else diab_eye = -9;

	if diabw&yy.f>0 then domain=1;
	else do;
	  domain=2;
	  diabw&yy.f=1;
	end;
run;

proc format;
	value diab_eye
	 1 = "In the past year"
	 2 = "More than 1 year ago"
	 3 = "Never had eye exam"
	 4 = "No exam in past year"
	-1 = "Inapplicable"
	-7 = "Don't know/Non-response"
	-9 = "Missing";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
	FORMAT diab_eye diab_eye. &fmt.;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT DIABW&yy.F;
	TABLES domain*&gp.*diab_eye / row;
run;

proc print data = out;
	where domain = 1 and diab_eye ne . &where.;
	var diab_eye &gp. WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
