/* Event type */
	data MEPS; set MEPS;
		HHTEXP&yy. = HHAEXP&yy. + HHNEXP&yy.; /* Home Health Agency + Independent providers */
		ERTEXP&yy. = ERFEXP&yy. + ERDEXP&yy.; /* Doctor + Facility Expenses for OP, ER, IP events */
		IPTEXP&yy. = IPFEXP&yy. + IPDEXP&yy.;
		OPTEXP&yy. = OPFEXP&yy. + OPDEXP&yy.; /* All Outpatient */
		OPYEXP&yy. = OPVEXP&yy. + OPSEXP&yy.; /* Physician only */
		OPZEXP&yy. = OPOEXP&yy. + OPPEXP&yy.; /* non-physician only */
		OMAEXP&yy. = VISEXP&yy. + OTHEXP&yy.;

		TOTUSE&yy. =
			((DVTOT&yy. > 0) + (RXTOT&yy. > 0) + (OBTOTV&yy. > 0) +
			(OPTOTV&yy. > 0) + (ERTOT&yy. > 0) + (IPDIS&yy. > 0) +
			(HHTOTD&yy. > 0) + (OMAEXP&yy. > 0));
	run;
