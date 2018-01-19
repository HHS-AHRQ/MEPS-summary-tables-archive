ods output Domain = out;

data eventNA; set all_events;
	array vars XP&yy.X SF&yy.X MR&yy.X MD&yy.X PR&yy.X OZ&yy.X;
	do over vars;
		if vars <= 0 then vars = 0; else vars = 1;
	end;
run;

proc surveymeans data = eventNA sum ;
	&format.;
	stratum VARSTR;
	cluster VARPSU;
	weight PERWT&yy.F;
	var XP&yy.X SF&yy.X MR&yy.X MD&yy.X PR&yy.X OZ&yy.X;
	domain Condition;
run;
