/* Load event files */
  %load_events(RX,&RX.);
  %load_events(DV,&DV.);
  %load_events(IP,&IP.);
  %load_events(ER,&ER.);
  %load_events(OP,&OP.);
  %load_events(OB,&OB.);
  %load_events(HH,&HH.);

/* Define sub-levels for office-based, outpatient, and home health */
/* To compute estimates for these sub-events, replace 'event' with 'event_v2X'
   in the 'proc surveymeans' statement below, when applicable */

  data OB; set OB;
  	if SEEDOC = 1 then event_v2X = 'OBD';
  	else if SEEDOC = 2 then event_v2X = 'OBO';
  	else event_v2X = '';
  run;

  data OP; set OP;
  	if SEEDOC = 1 then event_v2X = 'OPY';
  	else if SEEDOC = 2 then event_v2X = 'OPZ';
  	else event_v2X = '';
  run;

/* Merge with FYC file */
  data FYCsub; set MEPS;
  	keep &gp. DUPERSID PERWT&yy.F VARSTR VARPSU;
  run;
