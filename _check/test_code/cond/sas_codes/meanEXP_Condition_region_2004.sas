ods graphics off;

/* Read in dataset and initialize year */
FILENAME h89 "C:\MEPS\h89.ssp";
proc xcopy in = h89 out = WORK IMPORT;
run;

data MEPS;
 SET h89;
 ARRAY OLDVAR(5) VARPSU04 VARSTR04 WTDPER04 AGE2X AGE1X;
 year = 2004;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU04;
  VARSTR = VARSTR04;
 end;

 if year <= 1998 then do;
  PERWT04F = WTDPER04;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE04X >= 0 then AGELAST = AGE04x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Census Region */
data MEPS; set MEPS;
 ARRAY OLDREG(2) REGION1 REGION2;
 if year = 1996 then do;
  REGION42 = REGION2;
  REGION31 = REGION1;
 end;

 if REGION04 >= 0 then region = REGION04;
 else if REGION42 >= 0 then region = REGION42;
 else if REGION31 >= 0 then region = REGION31;
 else region = .;
run;

proc format;
 value region
 1 = "Northeast"
 2 = "Midwest"
 3 = "South"
 4 = "West"
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
  year = 2004;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH04X &evnt.FCH04X SEEDOC ;
   SF04X = &evnt.DSF04X + &evnt.FSF04X;
   MR04X = &evnt.DMR04X + &evnt.FMR04X;
   MD04X = &evnt.DMD04X + &evnt.FMD04X;
   PV04X = &evnt.DPV04X + &evnt.FPV04X;
   VA04X = &evnt.DVA04X + &evnt.FVA04X;
   OF04X = &evnt.DOF04X + &evnt.FOF04X;
   SL04X = &evnt.DSL04X + &evnt.FSL04X;
   WC04X = &evnt.DWC04X + &evnt.FWC04X;
   OR04X = &evnt.DOR04X + &evnt.FOR04X;
   OU04X = &evnt.DOU04X + &evnt.FOU04X;
   OT04X = &evnt.DOT04X + &evnt.FOT04X;
   XP04X = &evnt.DXP04X + &evnt.FXP04X;

   if year <= 1999 then TR04X = &evnt.DCH04X + &evnt.FCH04X;
   else TR04X = &evnt.DTR04X + &evnt.FTR04X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH04X SEEDOC ;
   SF04X = &evnt.SF04X;
   MR04X = &evnt.MR04X;
   MD04X = &evnt.MD04X;
   PV04X = &evnt.PV04X;
   VA04X = &evnt.VA04X;
   OF04X = &evnt.OF04X;
   SL04X = &evnt.SL04X;
   WC04X = &evnt.WC04X;
   OR04X = &evnt.OR04X;
   OU04X = &evnt.OU04X;
   OT04X = &evnt.OT04X;
   XP04X = &evnt.XP04X;

   if year <= 1999 then TR04X = &evnt.CH04X;
   else TR04X = &evnt.TR04X;
  %end;

  PR04X = PV04X + TR04X;
  OZ04X = OF04X + SL04X + OT04X + OR04X + OU04X + WC04X + VA04X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP04X SF04X PR04X MR04X MD04X OZ04X;
 run;
%mend;

%load_events(RX,h85a);
%load_events(DV,h85b);
%load_events(IP,h85d);
%load_events(ER,h85e);
%load_events(OP,h85f);
%load_events(OB,h85g);
%load_events(HH,h85h);

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
 keep region DUPERSID PERWT04F VARSTR VARPSU;
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
 var SF04X MR04X MD04X XP04X PR04X OZ04X;
 output out = RXpers sum = ;
run;

data stacked_events;
 set RXpers IP ER OP OB HH;
 where XP04X >= 0;
 count = 1;
 ind = 1;
run;

/* Read in event-condition linking file */
FILENAME h85if1 "C:\MEPS\h85if1.ssp";
proc xcopy in = h85if1 out = WORK IMPORT; run;
data clink1;
 set &syslast;
 keep DUPERSID CONDIDX EVNTIDX;
run;

FILENAME h87 "C:\MEPS\h87.ssp";
proc xcopy in = h87 out = WORK IMPORT; run;
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
 if condition in ("-1","-9","") or XP04X < 0 then delete;
run;

proc sort data = FYCsub; by DUPERSID; run;
data all_events;
 merge event_cond FYCsub;
 by DUPERSID;
 count = 1;
 ind = 1;
run;

proc sort data = all_events;
 by region DUPERSID VARSTR VARPSU PERWT04F Condition ind count;
run;

proc means data = all_events noprint;
 by region DUPERSID VARSTR VARPSU PERWT04F Condition ind count;
 var SF04X MR04X MD04X XP04X PR04X OZ04X;
 output out = all_pers sum = ;
run;

ods output Domain = out;
proc surveymeans data = all_pers mean ;
 FORMAT region region.;
 stratum VARSTR;
 cluster VARPSU;
 weight PERWT04F;
 var XP04X;
 domain Condition*region ;
run;
