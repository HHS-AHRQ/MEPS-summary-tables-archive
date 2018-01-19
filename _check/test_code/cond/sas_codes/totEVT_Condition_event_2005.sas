ods graphics off;

/* Read in dataset and initialize year */
FILENAME h97 "C:\MEPS\h97.ssp";
proc xcopy in = h97 out = WORK IMPORT;
run;

data MEPS;
 SET h97;
 ARRAY OLDVAR(5) VARPSU05 VARSTR05 WTDPER05 AGE2X AGE1X;
 year = 2005;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU05;
  VARSTR = VARSTR05;
 end;

 if year <= 1998 then do;
  PERWT05F = WTDPER05;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE05X >= 0 then AGELAST = AGE05x;
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
  year = 2005;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH05X &evnt.FCH05X SEEDOC ;
   SF05X = &evnt.DSF05X + &evnt.FSF05X;
   MR05X = &evnt.DMR05X + &evnt.FMR05X;
   MD05X = &evnt.DMD05X + &evnt.FMD05X;
   PV05X = &evnt.DPV05X + &evnt.FPV05X;
   VA05X = &evnt.DVA05X + &evnt.FVA05X;
   OF05X = &evnt.DOF05X + &evnt.FOF05X;
   SL05X = &evnt.DSL05X + &evnt.FSL05X;
   WC05X = &evnt.DWC05X + &evnt.FWC05X;
   OR05X = &evnt.DOR05X + &evnt.FOR05X;
   OU05X = &evnt.DOU05X + &evnt.FOU05X;
   OT05X = &evnt.DOT05X + &evnt.FOT05X;
   XP05X = &evnt.DXP05X + &evnt.FXP05X;

   if year <= 1999 then TR05X = &evnt.DCH05X + &evnt.FCH05X;
   else TR05X = &evnt.DTR05X + &evnt.FTR05X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH05X SEEDOC ;
   SF05X = &evnt.SF05X;
   MR05X = &evnt.MR05X;
   MD05X = &evnt.MD05X;
   PV05X = &evnt.PV05X;
   VA05X = &evnt.VA05X;
   OF05X = &evnt.OF05X;
   SL05X = &evnt.SL05X;
   WC05X = &evnt.WC05X;
   OR05X = &evnt.OR05X;
   OU05X = &evnt.OU05X;
   OT05X = &evnt.OT05X;
   XP05X = &evnt.XP05X;

   if year <= 1999 then TR05X = &evnt.CH05X;
   else TR05X = &evnt.TR05X;
  %end;

  PR05X = PV05X + TR05X;
  OZ05X = OF05X + SL05X + OT05X + OR05X + OU05X + WC05X + VA05X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP05X SF05X PR05X MR05X MD05X OZ05X;
 run;
%mend;

%load_events(RX,h94a);
%load_events(DV,h94b);
%load_events(IP,h94d);
%load_events(ER,h94e);
%load_events(OP,h94f);
%load_events(OB,h94g);
%load_events(HH,h94h);

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
 keep ind DUPERSID PERWT05F VARSTR VARPSU;
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
 var SF05X MR05X MD05X XP05X PR05X OZ05X;
 output out = RXpers sum = ;
run;

data stacked_events;
 set RXpers IP ER OP OB HH;
 where XP05X >= 0;
 count = 1;
 ind = 1;
run;

/* Read in event-condition linking file */
FILENAME h94if1 "C:\MEPS\h94if1.ssp";
proc xcopy in = h94if1 out = WORK IMPORT; run;
data clink1;
 set &syslast;
 keep DUPERSID CONDIDX EVNTIDX;
run;

FILENAME h96 "C:\MEPS\h96.ssp";
proc xcopy in = h96 out = WORK IMPORT; run;
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
 if condition in ("-1","-9","") or XP05X < 0 then delete;
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
 weight PERWT05F;
 var count;
 domain Condition*event ;
run;
