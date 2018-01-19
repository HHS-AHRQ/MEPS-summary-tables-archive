/* Insurance coverage */
/* To compute for insurance categories, replace 'insurance' in the SURVEY procedure with 'insurance_v2X' */
data MEPS; set MEPS;
	ARRAY OLDINS(4) MCDEVER MCREVER OPAEVER OPBEVER;
	if year = 1996 then do;
		MCDEV96 = MCDEVER;
		MCREV96 = MCREVER;
		OPAEV96 = OPAEVER;
		OPBEV96 = OPBEVER;
	end;

	if year < 2011 then do;
		public   = (MCDEV&yy. = 1) or (OPAEV&yy.=1) or (OPBEV&yy.=1);
		medicare = (MCREV&yy.=1);
		private  = (INSCOV&yy.=1);

		mcr_priv = (medicare and  private);
		mcr_pub  = (medicare and ~private and public);
		mcr_only = (medicare and ~private and ~public);
		no_mcr   = (~medicare);

		ins_gt65 = 4*mcr_only + 5*mcr_priv + 6*mcr_pub + 7*no_mcr;

		if AGELAST < 65 then INSURC&yy. = INSCOV&yy.;
		else INSURC&yy. = ins_gt65;
	end;

	insurance = INSCOV&yy.;
	insurance_v2X = INSURC&yy.;
run;

proc format;
	value insurance
	1 = "Any private, all ages"
	2 = "Public only, all ages"
	3 = "Uninsured, all ages";

	value insurance_v2X
	1 = "<65, Any private"
	2 = "<65, Public only"
	3 = "<65, Uninsured"
	4 = "65+, Medicare only"
	5 = "65+, Medicare and private"
	6 = "65+, Medicare and other public"
	7 = "65+, No medicare"
	8 = "65+, No medicare";
run;
