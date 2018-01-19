/* Race by sex */
data MEPS; set MEPS;
	ARRAY RCEVAR(4) RACETHX RACEV1X RACETHNX RACEX;
	if year >= 2012 then do;
		hisp   = (RACETHX = 1);
 		white  = (RACETHX = 2);
      	black  = (RACETHX = 3);
      	native = (RACETHX > 3 and RACEV1X in (3,6));
      	asian  = (RACETHX > 3 and RACEV1X in (4,5));
		white_oth = 0;
	end;

	else if year >= 2002 then do;
		hisp   = (RACETHNX = 1);
		white  = (RACETHNX = 4 and RACEX = 1);
		black  = (RACETHNX = 2);
		native = (RACETHNX >= 3 and RACEX in (3,6));
		asian  = (RACETHNX >= 3 and RACEX in (4,5));
		white_oth = 0;
	end;

	else do;
		hisp  = (RACETHNX = 1);
		black = (RACETHNX = 2);
		white_oth = (RACETHNX = 3);
		white  = 0;
		native = 0;
		asian  = 0;
	end;

	race = 1*hisp + 2*white + 3*black + 4*native + 5*asian + 9*white_oth;

	if sex = 2 then racesex = race*-1;
	else racesex = race;
run;

proc format;
	value racesex
	1 = "Male, Hispanic"
	2 = "Male, White"
	3 = "Male, Black"
	4 = "Male, Amer. Indian, AK Native, or mult. races"
	5 = "Male, Asian, Hawaiian, or Pacific Islander"
	9 = "Male, White and other"
	-1 = "Female, Hispanic"
	-2 = "Female, White"
	-3 = "Female, Black"
	-4 = "Female, Amer. Indian, AK Native, or mult. races"
	-5 = "Female, Asian, Hawaiian, or Pacific Islander"
	-9 = "Female, White and other"
	. = "Missing";
run;
