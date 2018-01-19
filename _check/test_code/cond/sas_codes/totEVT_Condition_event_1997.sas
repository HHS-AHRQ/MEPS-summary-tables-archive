ods graphics off;

/* Read in dataset and initialize year */
FILENAME h20 "C:\MEPS\h20.ssp";
proc xcopy in = h20 out = WORK IMPORT;
run;

data MEPS;
 SET h20;
 ARRAY OLDVAR(5) VARPSU97 VARSTR97 WTDPER97 AGE2X AGE1X;
 year = 1997;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU97;
  VARSTR = VARSTR97;
 end;

 if year <= 1998 then do;
  PERWT97F = WTDPER97;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE97X >= 0 then AGELAST = AGE97x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
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
  year = 1997;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH97X &evnt.FCH97X SEEDOC ;
   SF97X = &evnt.DSF97X + &evnt.FSF97X;
   MR97X = &evnt.DMR97X + &evnt.FMR97X;
   MD97X = &evnt.DMD97X + &evnt.FMD97X;
   PV97X = &evnt.DPV97X + &evnt.FPV97X;
   VA97X = &evnt.DVA97X + &evnt.FVA97X;
   OF97X = &evnt.DOF97X + &evnt.FOF97X;
   SL97X = &evnt.DSL97X + &evnt.FSL97X;
   WC97X = &evnt.DWC97X + &evnt.FWC97X;
   OR97X = &evnt.DOR97X + &evnt.FOR97X;
   OU97X = &evnt.DOU97X + &evnt.FOU97X;
   OT97X = &evnt.DOT97X + &evnt.FOT97X;
   XP97X = &evnt.DXP97X + &evnt.FXP97X;

   if year <= 1999 then TR97X = &evnt.DCH97X + &evnt.FCH97X;
   else TR97X = &evnt.DTR97X + &evnt.FTR97X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH97X SEEDOC ;
   SF97X = &evnt.SF97X;
   MR97X = &evnt.MR97X;
   MD97X = &evnt.MD97X;
   PV97X = &evnt.PV97X;
   VA97X = &evnt.VA97X;
   OF97X = &evnt.OF97X;
   SL97X = &evnt.SL97X;
   WC97X = &evnt.WC97X;
   OR97X = &evnt.OR97X;
   OU97X = &evnt.OU97X;
   OT97X = &evnt.OT97X;
   XP97X = &evnt.XP97X;

   if year <= 1999 then TR97X = &evnt.CH97X;
   else TR97X = &evnt.TR97X;
  %end;

  PR97X = PV97X + TR97X;
  OZ97X = OF97X + SL97X + OT97X + OR97X + OU97X + WC97X + VA97X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP97X SF97X PR97X MR97X MD97X OZ97X;
 run;
%mend;

%load_events(RX,h16a);
%load_events(DV,hc16bf1);
%load_events(IP,hc16df1);
%load_events(ER,hc16ef1);
%load_events(OP,hc16ff1);
%load_events(OB,hc16gf1);
%load_events(HH,hc16hf1);

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
 keep ind DUPERSID PERWT97F VARSTR VARPSU;
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
 var SF97X MR97X MD97X XP97X PR97X OZ97X;
 output out = RXpers sum = ;
run;

data stacked_events;
 set RXpers IP ER OP OB HH;
 where XP97X >= 0;
 count = 1;
 ind = 1;
run;

/* Read in event-condition linking file */
FILENAME h16if1 "C:\MEPS\h16if1.ssp";
proc xcopy in = h16if1 out = WORK IMPORT; run;
data clink1;
 set &syslast;
 keep DUPERSID CONDIDX EVNTIDX;
run;

FILENAME h18 "C:\MEPS\h18.ssp";
proc xcopy in = h18 out = WORK IMPORT; run;
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
 if condition in ("-1","-9","") or XP97X < 0 then delete;
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
 FORMAT ind ind.;
 stratum VARSTR;
 cluster VARPSU;
 weight PERWT97F;
 var count;
 domain Condition*event ;
run;
