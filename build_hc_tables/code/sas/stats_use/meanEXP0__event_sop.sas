%let exp_vars =
	TOTEXP&yy. DVTEXP&yy. RXEXP&yy.  OBVEXP&yy. OBDEXP&yy.
	OPTEXP&yy. OPYEXP&yy. ERTEXP&yy.
	IPTEXP&yy. HHTEXP&yy. OMAEXP&yy.

	TOTSLF&yy. DVTSLF&yy.	RXSLF&yy.  OBVSLF&yy. OBDSLF&yy.
	OPTSLF&yy. OPYSLF&yy. ERTSLF&yy.
	IPTSLF&yy. HHTSLF&yy.	OMASLF&yy.

	TOTPTR&yy. DVTPTR&yy. RXPTR&yy.  OBVPTR&yy. OBDPTR&yy.
	OPTPTR&yy. OPYPTR&yy. ERTPTR&yy.
	IPTPTR&yy. HHTPTR&yy. OMAPTR&yy.

	TOTMCR&yy. DVTMCR&yy. RXMCR&yy. OBVMCR&yy. OBDMCR&yy.
	OPTMCR&yy. OPYMCR&yy. ERTMCR&yy.
	IPTMCR&yy. HHTMCR&yy. OMAMCR&yy.

	TOTMCD&yy. DVTMCD&yy. RXMCD&yy.  OBVMCD&yy. OBDMCD&yy.
	OPTMCD&yy. OPYMCD&yy. ERTMCD&yy.
	IPTMCD&yy. HHTMCD&yy. OMAMCD&yy.

	TOTOTZ&yy. DVTOTZ&yy. RXOTZ&yy.  OBVOTZ&yy. OBDOTZ&yy.
	OPTOTZ&yy. OPYOTZ&yy. ERTOTZ&yy.
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
