/* Event type and source of payment */
	%macro add_sops(event);
		if year <= 1999 then do;
			&event.TRI&yy. = &event.CHM&yy.;
		end;

		&event.OTH&yy. = &event.OFD&yy. + &event.STL&yy. + &event.OPR&yy. + &event.OPU&yy. + &event.OSR&yy.;
		&event.OTZ&yy. = &event.OTH&yy. + &event.WCP&yy. + &event.VA&yy.;
		&event.PTR&yy. = &event.PRV&yy. + &event.TRI&yy.;
	%mend;

	%macro add_events(sop);
		HHT&sop.&yy. = HHA&sop.&yy. + HHN&sop.&yy.; /* Home Health Agency + Independent providers */
		ERT&sop.&yy. = ERF&sop.&yy. + ERD&sop.&yy.; /* Doctor + Facility expenses for OP, ER, IP events */
		IPT&sop.&yy. = IPF&sop.&yy. + IPD&sop.&yy.;
		OPT&sop.&yy. = OPF&sop.&yy. + OPD&sop.&yy.; /* All Outpatient */
		OPY&sop.&yy. = OPV&sop.&yy. + OPS&sop.&yy.; /* Outpatient - Physician only */
		OMA&sop.&yy. = VIS&sop.&yy. + OTH&sop.&yy.;
	%mend;

	%macro add_event_sops;
		%let sops = EXP SLF PTR MCR MCD OTZ;
		%let events =
				TOT DVT RX  OBV OBD
				OPF OPD OPV OPS
				ERF ERD IPF IPD HHA HHN
				VIS OTH;

		data MEPS; set MEPS;
			%do i = 1 %to 20;
				%add_sops(event = %scan(&events, &i));
			%end;

			%do i = 1 %to 6;
				%add_events(sop = %scan(&sops, &i));
			%end;
		run;
	%mend;

	%add_event_sops;
