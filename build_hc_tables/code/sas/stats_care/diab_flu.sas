/* Diabetes care: Flu shot */
data MEPS; set MEPS;
	ARRAY FLUVAR(5) FLUSHT53 DSFLNV53 DSFL&yb.53 DSFL&yy.53 DSFL&ya.53;
	if year > 2007 then do;
		past_year = (DSFL&yy.53=1 | DSFL&ya.53=1);
		more_year = (DSFL&yb.53=1 | DSVB&yb.53=1);
		never_chk = (DSFLNV53 = 1);
		non_resp  = (DSFL&yy.53 in (-7,-8,-9));
	end;

	else do;
		past_year = (FLUSHT53 = 1);
		more_year = (1 < FLUSHT53 & FLUSHT53 < 6);
		never_chk = (FLUSHT53 = 6);
		non_resp  = (FLUSHT53 in (-7,-8,-9));
	end;

	if past_year = 1 then diab_flu = 1;
	else if more_year = 1 then diab_flu = 2;
	else if never_chk = 1 then diab_flu = 3;
	else if non_resp = 1  then diab_flu = -7;
	else diab_flu = -9;

	if diabw&yy.f>0 then domain=1;
	else do;
	  domain=2;
	  diabw&yy.f=1;
	end;
run;

proc format;
	value diab_flu
	 1 = "In the past year"
	 2 = "More than 1 year ago"
	 3 = "Never had flu shot"
	 4 = "No flu shot in past year"
	-1 = "Inapplicable"
	-7 = "Don't know/Non-response"
	-9 = "Missing";
run;

ods output CrossTabs = out;
proc surveyfreq data = MEPS missing;
	FORMAT diab_flu diab_flu. &fmt.;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT DIABW&yy.F;
	TABLES domain*&gp.*diab_flu / row;
run;

proc print data = out;
	where domain = 1 and diab_flu ne . &where.;
	var diab_flu &gp. WgtFreq StdDev Frequency RowPercent RowStdErr;
run;
