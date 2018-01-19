ods graphics off;

/* Read in dataset and initialize year */
FILENAME h70 "C:\MEPS\h70.ssp";
proc xcopy in = h70 out = WORK IMPORT;
run;

data MEPS;
 SET h70;
 ARRAY OLDVAR(5) VARPSU02 VARSTR02 WTDPER02 AGE2X AGE1X;
 year = 2002;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU02;
  VARSTR = VARSTR02;
 end;

 if year <= 1998 then do;
  PERWT02F = WTDPER02;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE02X >= 0 then AGELAST = AGE02x;
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
  year = 2002;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH02X &evnt.FCH02X SEEDOC ;
   SF02X = &evnt.DSF02X + &evnt.FSF02X;
   MR02X = &evnt.DMR02X + &evnt.FMR02X;
   MD02X = &evnt.DMD02X + &evnt.FMD02X;
   PV02X = &evnt.DPV02X + &evnt.FPV02X;
   VA02X = &evnt.DVA02X + &evnt.FVA02X;
   OF02X = &evnt.DOF02X + &evnt.FOF02X;
   SL02X = &evnt.DSL02X + &evnt.FSL02X;
   WC02X = &evnt.DWC02X + &evnt.FWC02X;
   OR02X = &evnt.DOR02X + &evnt.FOR02X;
   OU02X = &evnt.DOU02X + &evnt.FOU02X;
   OT02X = &evnt.DOT02X + &evnt.FOT02X;
   XP02X = &evnt.DXP02X + &evnt.FXP02X;

   if year <= 1999 then TR02X = &evnt.DCH02X + &evnt.FCH02X;
   else TR02X = &evnt.DTR02X + &evnt.FTR02X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH02X SEEDOC ;
   SF02X = &evnt.SF02X;
   MR02X = &evnt.MR02X;
   MD02X = &evnt.MD02X;
   PV02X = &evnt.PV02X;
   VA02X = &evnt.VA02X;
   OF02X = &evnt.OF02X;
   SL02X = &evnt.SL02X;
   WC02X = &evnt.WC02X;
   OR02X = &evnt.OR02X;
   OU02X = &evnt.OU02X;
   OT02X = &evnt.OT02X;
   XP02X = &evnt.XP02X;

   if year <= 1999 then TR02X = &evnt.CH02X;
   else TR02X = &evnt.TR02X;
  %end;

  PR02X = PV02X + TR02X;
  OZ02X = OF02X + SL02X + OT02X + OR02X + OU02X + WC02X + VA02X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP02X SF02X PR02X MR02X MD02X OZ02X;
 run;
%mend;

%load_events(RX,h67a);
%load_events(DV,h67b);
%load_events(IP,h67d);
%load_events(ER,h67e);
%load_events(OP,h67f);
%load_events(OB,h67g);
%load_events(HH,h67h);

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
 keep ind DUPERSID PERWT02F VARSTR VARPSU;
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
 var SF02X MR02X MD02X XP02X PR02X OZ02X;
 output out = RXpers sum = ;
run;

data stacked_events;
 set RXpers IP ER OP OB HH;
 where XP02X >= 0;
 count = 1;
 ind = 1;
run;

/* Read in event-condition linking file */
FILENAME h67if1 "C:\MEPS\h67if1.ssp";
proc xcopy in = h67if1 out = WORK IMPORT; run;
data clink1;
 set &syslast;
 keep DUPERSID CONDIDX EVNTIDX;
run;

FILENAME h69 "C:\MEPS\h69.ssp";
proc xcopy in = h69 out = WORK IMPORT; run;
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
 if condition in ("-1","-9","") or XP02X < 0 then delete;
run;

proc sort data = FYCsub; by DUPERSID; run;
data all_events;
 merge event_cond FYCsub;
 by DUPERSID;
 count = 1;
 ind = 1;
run;

ods output Domain = out;

data eventNA; set all_events;
 array vars XP02X SF02X MR02X MD02X PR02X OZ02X;
 do over vars;
  if vars <= 0 then vars = 0; else vars = 1;
 end;
run;

proc surveymeans data = eventNA sum ;
 FORMAT ind ind.;
 stratum VARSTR;
 cluster VARPSU;
 weight PERWT02F;
 var XP02X SF02X MR02X MD02X PR02X OZ02X;
 domain Condition;
run;
