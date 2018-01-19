ods graphics off;

/* Read in dataset and initialize year */
FILENAME h60 "C:\MEPS\h60.ssp";
proc xcopy in = h60 out = WORK IMPORT;
run;

data MEPS;
 SET h60;
 ARRAY OLDVAR(5) VARPSU01 VARSTR01 WTDPER01 AGE2X AGE1X;
 year = 2001;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU01;
  VARSTR = VARSTR01;
 end;

 if year <= 1998 then do;
  PERWT01F = WTDPER01;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE01X >= 0 then AGELAST = AGE01x;
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
  year = 2001;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH01X &evnt.FCH01X SEEDOC ;
   SF01X = &evnt.DSF01X + &evnt.FSF01X;
   MR01X = &evnt.DMR01X + &evnt.FMR01X;
   MD01X = &evnt.DMD01X + &evnt.FMD01X;
   PV01X = &evnt.DPV01X + &evnt.FPV01X;
   VA01X = &evnt.DVA01X + &evnt.FVA01X;
   OF01X = &evnt.DOF01X + &evnt.FOF01X;
   SL01X = &evnt.DSL01X + &evnt.FSL01X;
   WC01X = &evnt.DWC01X + &evnt.FWC01X;
   OR01X = &evnt.DOR01X + &evnt.FOR01X;
   OU01X = &evnt.DOU01X + &evnt.FOU01X;
   OT01X = &evnt.DOT01X + &evnt.FOT01X;
   XP01X = &evnt.DXP01X + &evnt.FXP01X;

   if year <= 1999 then TR01X = &evnt.DCH01X + &evnt.FCH01X;
   else TR01X = &evnt.DTR01X + &evnt.FTR01X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH01X SEEDOC ;
   SF01X = &evnt.SF01X;
   MR01X = &evnt.MR01X;
   MD01X = &evnt.MD01X;
   PV01X = &evnt.PV01X;
   VA01X = &evnt.VA01X;
   OF01X = &evnt.OF01X;
   SL01X = &evnt.SL01X;
   WC01X = &evnt.WC01X;
   OR01X = &evnt.OR01X;
   OU01X = &evnt.OU01X;
   OT01X = &evnt.OT01X;
   XP01X = &evnt.XP01X;

   if year <= 1999 then TR01X = &evnt.CH01X;
   else TR01X = &evnt.TR01X;
  %end;

  PR01X = PV01X + TR01X;
  OZ01X = OF01X + SL01X + OT01X + OR01X + OU01X + WC01X + VA01X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP01X SF01X PR01X MR01X MD01X OZ01X;
 run;
%mend;

%load_events(RX,h59a);
%load_events(DV,h59b);
%load_events(IP,h59d);
%load_events(ER,h59e);
%load_events(OP,h59f);
%load_events(OB,h59g);
%load_events(HH,h59h);

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
 keep mnhlth DUPERSID PERWT01F VARSTR VARPSU;
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
 var SF01X MR01X MD01X XP01X PR01X OZ01X;
 output out = RXpers sum = ;
run;

data stacked_events;
 set RXpers IP ER OP OB HH;
 where XP01X >= 0;
 count = 1;
 ind = 1;
run;

/* Read in event-condition linking file */
FILENAME h59if1 "C:\MEPS\h59if1.ssp";
proc xcopy in = h59if1 out = WORK IMPORT; run;
data clink1;
 set &syslast;
 keep DUPERSID CONDIDX EVNTIDX;
run;

FILENAME h61 "C:\MEPS\h61.ssp";
proc xcopy in = h61 out = WORK IMPORT; run;
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
 if condition in ("-1","-9","") or XP01X < 0 then delete;
run;

proc sort data = FYCsub; by DUPERSID; run;
data all_events;
 merge event_cond FYCsub;
 by DUPERSID;
 count = 1;
 ind = 1;
run;

proc sort data = all_events;
 by mnhlth DUPERSID VARSTR VARPSU PERWT01F Condition ind count;
run;

proc means data = all_events noprint;
 by mnhlth DUPERSID VARSTR VARPSU PERWT01F Condition ind count;
 var SF01X MR01X MD01X XP01X PR01X OZ01X;
 output out = all_pers sum = ;
run;

ods output Domain = out;
proc surveymeans data = all_pers sum ;
 FORMAT mnhlth mnhlth.;
 stratum VARSTR;
 cluster VARPSU;
 weight PERWT01F;
 var count;
 domain Condition*mnhlth ;
run;
