ods graphics off;

/* Read in dataset and initialize year */
FILENAME h79 "C:\MEPS\h79.ssp";
proc xcopy in = h79 out = WORK IMPORT;
run;

data MEPS;
 SET h79;
 ARRAY OLDVAR(5) VARPSU03 VARSTR03 WTDPER03 AGE2X AGE1X;
 year = 2003;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU03;
  VARSTR = VARSTR03;
 end;

 if year <= 1998 then do;
  PERWT03F = WTDPER03;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE03X >= 0 then AGELAST = AGE03x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Perceived mental health */
data MEPS; set MEPS;
 ARRAY OLDMNH(2) MNTHLTH1 MNTHLTH2;
 if year = 1996 then do;
  MNHLTH53 = MNTHLTH2;
  MNHLTH42 = MNTHLTH2;
  MNHLTH31 = MNTHLTH1;
 end;

 if MNHLTH53 ge 0 then mnhlth = MNHLTH53;
 else if MNHLTH42 ge 0 then mnhlth = MNHLTH42;
 else if MNHLTH31 ge 0 then mnhlth = MNHLTH31;
 else mnhlth = .;
run;

proc format;
 value mnhlth
 1 = "Excellent"
 2 = "Very good"
 3 = "Good"
 4 = "Fair"
 5 = "Poor"
 . = "Missing";
run;

/* Load event files */
%macro load_events(evnt,file) / minoperator;

 FILENAME &file. "C:\MEPS\&file..ssp";
 proc xcopy in = &file. out = WORK IMPORT;
 run;

 data &evnt;
  SET &syslast; /* Most recent dataset loaded */
  ARRAY OLDVARS(2) LINKIDX EVNTIDX;
  event = "&evnt.";
  year = 2003;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH03X &evnt.FCH03X SEEDOC ;
   SF03X = &evnt.DSF03X + &evnt.FSF03X;
   MR03X = &evnt.DMR03X + &evnt.FMR03X;
   MD03X = &evnt.DMD03X + &evnt.FMD03X;
   PV03X = &evnt.DPV03X + &evnt.FPV03X;
   VA03X = &evnt.DVA03X + &evnt.FVA03X;
   OF03X = &evnt.DOF03X + &evnt.FOF03X;
   SL03X = &evnt.DSL03X + &evnt.FSL03X;
   WC03X = &evnt.DWC03X + &evnt.FWC03X;
   OR03X = &evnt.DOR03X + &evnt.FOR03X;
   OU03X = &evnt.DOU03X + &evnt.FOU03X;
   OT03X = &evnt.DOT03X + &evnt.FOT03X;
   XP03X = &evnt.DXP03X + &evnt.FXP03X;

   if year <= 1999 then TR03X = &evnt.DCH03X + &evnt.FCH03X;
   else TR03X = &evnt.DTR03X + &evnt.FTR03X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH03X SEEDOC ;
   SF03X = &evnt.SF03X;
   MR03X = &evnt.MR03X;
   MD03X = &evnt.MD03X;
   PV03X = &evnt.PV03X;
   VA03X = &evnt.VA03X;
   OF03X = &evnt.OF03X;
   SL03X = &evnt.SL03X;
   WC03X = &evnt.WC03X;
   OR03X = &evnt.OR03X;
   OU03X = &evnt.OU03X;
   OT03X = &evnt.OT03X;
   XP03X = &evnt.XP03X;

   if year <= 1999 then TR03X = &evnt.CH03X;
   else TR03X = &evnt.TR03X;
  %end;

  PR03X = PV03X + TR03X;
  OZ03X = OF03X + SL03X + OT03X + OR03X + OU03X + WC03X + VA03X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP03X SF03X PR03X MR03X MD03X OZ03X;
 run;
%mend;

%load_events(RX,h77a);
%load_events(DV,h77b);
%load_events(IP,h77d);
%load_events(ER,h77e);
%load_events(OP,h77f);
%load_events(OB,h77g);
%load_events(HH,h77h);

/* Define sub-levels for office-based, outpatient, and home health */
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
 keep mnhlth DUPERSID PERWT03F VARSTR VARPSU;
run;

proc format;
 value CCCFMT
  -9 - -1                = [2.]
  1-9                    = 'Infectious diseases                                         '
  11-45                  = 'Cancer                                                      '
  46, 47                 = 'Non-malignant neoplasm                                      '
  48                     = 'Thyroid disease                                             '
  49,50                  = 'Diabetes mellitus                                           '
  51, 52, 54 - 58        = 'Other endocrine, nutritional & immune disorder              '
  53                     = 'Hyperlipidemia                                              '
  59                     = 'Anemia and other deficiencies                               '
  60-64                  = 'Hemorrhagic, coagulation, and disorders of White Blood cells'
  65-75, 650-670         = 'Mental disorders                                            '
  76-78                  = 'CNS infection                                               '
  79-81                  = 'Hereditary, degenerative and other nervous system disorders '
  82                     = 'Paralysis                                                   '
  84                     = 'Headache                                                    '
  83                     = 'Epilepsy and convulsions                                    '
  85                     = 'Coma, brain damage                                          '
  86                     = 'Cataract                                                    '
  88                     = 'Glaucoma                                                    '
  87, 89-91              = 'Other eye disorders                                         '
  92                     = 'Otitis media                                                '
  93-95                  = 'Other CNS disorders                                         '
  98,99                  = 'Hypertension                                                '
  96, 97, 100-108        = 'Heart disease                                               '
  109-113                = 'Cerebrovascular disease                                     '
  114 -121               = 'Other circulatory conditions arteries, veins, and lymphatics'
  122                    = 'Pneumonia                                                   '
  123                    = 'Influenza                                                   '
  124                    = 'Tonsillitis                                                 '
  125 , 126              = 'Acute Bronchitis and URI                                    '
  127-134                = 'COPD, asthma                                                '
  135                    = 'Intestinal infection                                        '
  136                    = 'Disorders of teeth and jaws                                 '
  137                    = 'Disorders of mouth and esophagus                            '
  138-141                = 'Disorders of the upper GI                                   '
  142                    = 'Appendicitis                                                '
  143                    = 'Hernias                                                     '
  144- 148               = 'Other stomach and intestinal disorders                      '
  153-155                = 'Other GI                                                    '
  149-152                = 'Gallbladder, pancreatic, and liver disease                  '
  156-158, 160, 161      = 'Kidney Disease                                              '
  159                    = 'Urinary tract infections                                    '
  162,163                = 'Other urinary                                               '
  164-166                = 'Male genital disorders                                      '
  167                    = 'Non-malignant breast disease                                '
  168-176                = 'Female genital disorders, and contraception                 '
  177-195                = 'Complications of pregnancy and birth                        '
  196, 218               = 'Normal birth/live born                                      '
  197-200                = 'Skin disorders                                              '
  201-204                = 'Osteoarthritis and other non-traumatic joint disorders      '
  205                    = 'Back problems                                               '
  206-209, 212           = 'Other bone and musculoskeletal disease                     '
  210-211                = 'Systemic lupus and connective tissues disorders             '
  213-217                = 'Congenital anomalies                                        '
  219-224                = 'Perinatal Conditions                                        '
  225-236, 239, 240, 244 = 'Trauma-related disorders                                    '
  237, 238               = 'Complications of surgery or device                          '
  241 - 243              = 'Poisoning by medical and non-medical substances             '
  259                    = 'Residual Codes                                              '
  10, 254-258            = 'Other care and screening                                    '
  245-252                = 'Symptoms                                                    '
  253                    = 'Allergic reactions                                          '
  OTHER                  = 'Other                                                       '
  ;
run;


data RX;
 set RX;
 EVNTIDX = LINKIDX;
run;

/* Sum RX purchases for each event */
proc sort data = RX; by event DUPERSID EVNTIDX; run;
proc means data = RX noprint;
 by event DUPERSID EVNTIDX;
 var SF03X MR03X MD03X XP03X PR03X OZ03X;
 output out = RXpers sum = ;
run;

data stacked_events;
 set RXpers IP ER OP OB HH;
 where XP03X >= 0;
 count = 1;
 ind = 1;
run;

/* Read in event-condition linking file */
FILENAME h77if1 "C:\MEPS\h77if1.ssp";
proc xcopy in = h77if1 out = WORK IMPORT; run;
data clink1;
 set &syslast;
 keep DUPERSID CONDIDX EVNTIDX;
run;

FILENAME h78 "C:\MEPS\h78.ssp";
proc xcopy in = h78 out = WORK IMPORT; run;
data Conditions;
 set &syslast;
 keep DUPERSID CONDIDX CCCODEX condition;
 CCS_code = CCCODEX*1;
 condition = PUT(CCS_code, CCCFMT.);
run;

proc sort data = clink1; by DUPERSID CONDIDX; run;
proc sort data = conditions; by DUPERSID CONDIDX; run;
data cond;
 merge clink1 conditions;
 by DUPERSID CONDIDX;
run;

proc sort data = cond nodupkey; by DUPERSID EVNTIDX condition; run;
proc sort data = stacked_events; by DUPERSID EVNTIDX; run;
data event_cond;
 merge stacked_events cond;
 by DUPERSID EVNTIDX;
 if condition in ("-1","-9","") or XP03X < 0 then delete;
run;

proc sort data = FYCsub; by DUPERSID; run;
data all_events;
 merge event_cond FYCsub;
 by DUPERSID;
 count = 1;
 ind = 1;
run;

ods output Domain = out;
proc surveymeans data = all_events sum ;
 FORMAT mnhlth mnhlth.;
 stratum VARSTR;
 cluster VARPSU;
 weight PERWT03F;
 var XP03X;
 domain Condition*mnhlth ;
run;
