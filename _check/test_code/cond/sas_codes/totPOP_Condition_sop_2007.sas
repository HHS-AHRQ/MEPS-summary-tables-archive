ods graphics off;

/* Read in dataset and initialize year */
FILENAME h113 "C:\MEPS\h113.ssp";
proc xcopy in = h113 out = WORK IMPORT;
run;

data MEPS;
 SET h113;
 ARRAY OLDVAR(5) VARPSU07 VARSTR07 WTDPER07 AGE2X AGE1X;
 year = 2007;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU07;
  VARSTR = VARSTR07;
 end;

 if year <= 1998 then do;
  PERWT07F = WTDPER07;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE07X >= 0 then AGELAST = AGE07x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Source of payment */
data MEPS; set MEPS;
 ARRAY OLDSOP(1) TOTCHM07;
 if year <= 1999 then do;
  TOTTRI07 = TOTCHM07;
 end;

 TOTOTH07 = TOTOFD07 + TOTSTL07 + TOTOPR07 + TOTOPU07 + TOTOSR07;
   TOTOTZ07 = TOTOTH07 + TOTWCP07 + TOTVA07;
   TOTPTR07 = TOTPRV07 + TOTTRI07;
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
  year = 2007;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH07X &evnt.FCH07X SEEDOC ;
   SF07X = &evnt.DSF07X + &evnt.FSF07X;
   MR07X = &evnt.DMR07X + &evnt.FMR07X;
   MD07X = &evnt.DMD07X + &evnt.FMD07X;
   PV07X = &evnt.DPV07X + &evnt.FPV07X;
   VA07X = &evnt.DVA07X + &evnt.FVA07X;
   OF07X = &evnt.DOF07X + &evnt.FOF07X;
   SL07X = &evnt.DSL07X + &evnt.FSL07X;
   WC07X = &evnt.DWC07X + &evnt.FWC07X;
   OR07X = &evnt.DOR07X + &evnt.FOR07X;
   OU07X = &evnt.DOU07X + &evnt.FOU07X;
   OT07X = &evnt.DOT07X + &evnt.FOT07X;
   XP07X = &evnt.DXP07X + &evnt.FXP07X;

   if year <= 1999 then TR07X = &evnt.DCH07X + &evnt.FCH07X;
   else TR07X = &evnt.DTR07X + &evnt.FTR07X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH07X SEEDOC ;
   SF07X = &evnt.SF07X;
   MR07X = &evnt.MR07X;
   MD07X = &evnt.MD07X;
   PV07X = &evnt.PV07X;
   VA07X = &evnt.VA07X;
   OF07X = &evnt.OF07X;
   SL07X = &evnt.SL07X;
   WC07X = &evnt.WC07X;
   OR07X = &evnt.OR07X;
   OU07X = &evnt.OU07X;
   OT07X = &evnt.OT07X;
   XP07X = &evnt.XP07X;

   if year <= 1999 then TR07X = &evnt.CH07X;
   else TR07X = &evnt.TR07X;
  %end;

  PR07X = PV07X + TR07X;
  OZ07X = OF07X + SL07X + OT07X + OR07X + OU07X + WC07X + VA07X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP07X SF07X PR07X MR07X MD07X OZ07X;
 run;
%mend;

%load_events(RX,h110a);
%load_events(DV,h110b);
%load_events(IP,h110d);
%load_events(ER,h110e);
%load_events(OP,h110f);
%load_events(OB,h110g);
%load_events(HH,h110h);

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
 keep ind DUPERSID PERWT07F VARSTR VARPSU;
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
 var SF07X MR07X MD07X XP07X PR07X OZ07X;
 output out = RXpers sum = ;
run;

data stacked_events;
 set RXpers IP ER OP OB HH;
 where XP07X >= 0;
 count = 1;
 ind = 1;
run;

/* Read in event-condition linking file */
FILENAME h110if1 "C:\MEPS\h110if1.ssp";
proc xcopy in = h110if1 out = WORK IMPORT; run;
data clink1;
 set &syslast;
 keep DUPERSID CONDIDX EVNTIDX;
run;

FILENAME h112 "C:\MEPS\h112.ssp";
proc xcopy in = h112 out = WORK IMPORT; run;
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
 if condition in ("-1","-9","") or XP07X < 0 then delete;
run;

proc sort data = FYCsub; by DUPERSID; run;
data all_events;
 merge event_cond FYCsub;
 by DUPERSID;
 count = 1;
 ind = 1;
run;

proc sort data = all_events;
 by ind DUPERSID VARSTR VARPSU PERWT07F Condition ind count;
run;

proc means data = all_events noprint;
 by ind DUPERSID VARSTR VARPSU PERWT07F Condition ind count;
 var SF07X MR07X MD07X XP07X PR07X OZ07X;
 output out = all_pers sum = ;
run;

data persNA; set all_pers;
 array vars XP07X SF07X MR07X MD07X PR07X OZ07X;
 do over vars;
  if vars <= 0 then vars = 0; else vars = 1;
 end;
run;

ods output Domain = out;
proc surveymeans data = persNA sum ;
 FORMAT ind ind.;
 stratum VARSTR;
 cluster VARPSU;
 weight PERWT07F;
 var XP07X SF07X MR07X MD07X PR07X OZ07X;
 domain Condition;
run;
