ods graphics off;

/* Read in dataset and initialize year */

FILENAME &RX. "&PUFdir.\&RX..ssp";
proc xcopy in = &RX. out = WORK IMPORT;
run;

data RX;
	set &syslast; 
	ARRAY OLDVAR(3) VARPSU&yy. VARSTR&yy. WTDPER&yy.;
	year = &year.;
	count = 1;

	if year <= 2001 then do;
		VARPSU = VARPSU&yy.;
		VARSTR = VARSTR&yy.;
	end;

	if year <= 1998 then do;
		PERWT&yy.F = WTDPER&yy.;
	end;

	domain = (RXNDC ne "-9");
run;
