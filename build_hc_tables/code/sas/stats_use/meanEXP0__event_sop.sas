%let exp_vars =
	TOTEXP&yy. DVTEXP&yy. RXEXP&yy.  OBVEXP&yy. OBDEXP&yy.
	OBOEXP&yy. OPTEXP&yy. OPYEXP&yy. OPZEXP&yy. ERTEXP&yy.
	IPTEXP&yy. HHTEXP&yy. OMAEXP&yy.

	TOTSLF&yy. DVTSLF&yy.	RXSLF&yy.  OBVSLF&yy. OBDSLF&yy.
	OBOSLF&yy. OPTSLF&yy.	OPYSLF&yy. OPZSLF&yy. ERTSLF&yy.
	IPTSLF&yy. HHTSLF&yy.	OMASLF&yy.

	TOTPTR&yy. DVTPTR&yy. RXPTR&yy.  OBVPTR&yy. OBDPTR&yy.
	OBOPTR&yy. OPTPTR&yy. OPYPTR&yy. OPZPTR&yy.	ERTPTR&yy.
	IPTPTR&yy. HHTPTR&yy. OMAPTR&yy.

	TOTMCR&yy. DVTMCR&yy. RXMCR&yy. OBVMCR&yy. OBDMCR&yy.
	OBOMCR&yy. OPTMCR&yy. OPYMCR&yy. OPZMCR&yy. ERTMCR&yy.
	IPTMCR&yy. HHTMCR&yy. OMAMCR&yy.

	TOTMCD&yy. DVTMCD&yy. RXMCD&yy.  OBVMCD&yy. OBDMCD&yy.
	OBOMCD&yy. OPTMCD&yy. OPYMCD&yy. OPZMCD&yy. ERTMCD&yy.
	IPTMCD&yy. HHTMCD&yy. OMAMCD&yy.

	TOTOTZ&yy. DVTOTZ&yy. RXOTZ&yy.  OBVOTZ&yy. OBDOTZ&yy.
	OBOOTZ&yy. OPTOTZ&yy. OPYOTZ&yy. OPZOTZ&yy. ERTOTZ&yy.
	IPTOTZ&yy. HHTOTZ&yy. OMAOTZ&yy.;

ods output Domain = out;
proc surveymeans data = MEPS mean missing nobs;
	&format.;
	VAR &exp_vars.;
	STRATA VARSTR;
	CLUSTER VARPSU;
	WEIGHT PERWT&yy.F;
	DOMAIN &domain.;
run;

proc print data = out;
run;
