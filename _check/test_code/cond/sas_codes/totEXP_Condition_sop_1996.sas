ods graphics off;

/* Read in dataset and initialize year */
FILENAME h12 "C:\MEPS\h12.ssp";
proc xcopy in = h12 out = WORK IMPORT;
run;

data MEPS;
 SET h12;
 ARRAY OLDVAR(5) VARPSU96 VARSTR96 WTDPER96 AGE2X AGE1X;
 year = 1996;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU96;
  VARSTR = VARSTR96;
 end;

 if year <= 1998 then do;
  PERWT96F = WTDPER96;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE96X >= 0 then AGELAST = AGE96x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Source of payment */
data MEPS; set MEPS;
 ARRAY OLDSOP(1) TOTCHM96;
 if year <= 1999 then do;
  TOTTRI96 = TOTCHM96;
 end;

 TOTOTH96 = TOTOFD96 + TOTSTL96 + TOTOPR96 + TOTOPU96 + TOTOSR96;
   TOTOTZ96 = TOTOTH96 + TOTWCP96 + TOTVA96;
   TOTPTR96 = TOTPRV96 + TOTTRI96;
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
  year = 1996;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH96X &evnt.FCH96X SEEDOC ;
   SF96X = &evnt.DSF96X + &evnt.FSF96X;
   MR96X = &evnt.DMR96X + &evnt.FMR96X;
   MD96X = &evnt.DMD96X + &evnt.FMD96X;
   PV96X = &evnt.DPV96X + &evnt.FPV96X;
   VA96X = &evnt.DVA96X + &evnt.FVA96X;
   OF96X = &evnt.DOF96X + &evnt.FOF96X;
   SL96X = &evnt.DSL96X + &evnt.FSL96X;
   WC96X = &evnt.DWC96X + &evnt.FWC96X;
   OR96X = &evnt.DOR96X + &evnt.FOR96X;
   OU96X = &evnt.DOU96X + &evnt.FOU96X;
   OT96X = &evnt.DOT96X + &evnt.FOT96X;
   XP96X = &evnt.DXP96X + &evnt.FXP96X;

   if year <= 1999 then TR96X = &evnt.DCH96X + &evnt.FCH96X;
   else TR96X = &evnt.DTR96X + &evnt.FTR96X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH96X SEEDOC ;
   SF96X = &evnt.SF96X;
   MR96X = &evnt.MR96X;
   MD96X = &evnt.MD96X;
   PV96X = &evnt.PV96X;
   VA96X = &evnt.VA96X;
   OF96X = &evnt.OF96X;
   SL96X = &evnt.SL96X;
   WC96X = &evnt.WC96X;
   OR96X = &evnt.OR96X;
   OU96X = &evnt.OU96X;
   OT96X = &evnt.OT96X;
   XP96X = &evnt.XP96X;

   if year <= 1999 then TR96X = &evnt.CH96X;
   else TR96X = &evnt.TR96X;
  %end;

  PR96X = PV96X + TR96X;
  OZ96X = OF96X + SL96X + OT96X + OR96X + OU96X + WC96X + VA96X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP96X SF96X PR96X MR96X MD96X OZ96X;
 run;
%mend;

%load_events(RX,hc10a);
%load_events(DV,hc10bf1);
%load_events(IP,hc10df1);
%load_events(ER,hc10ef1);
%load_events(OP,hc10ff1);
%load_events(OB,hc10gf1);
%load_events(HH,hc10hf1);

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
 keep ind DUPERSID PERWT96F VARSTR VARPSU;
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
 var SF96X MR96X MD96X XP96X PR96X OZ96X;
 output out = RXpers sum = ;
run;

data stacked_events;
 set RXpers IP ER OP OB HH;
 where XP96X >= 0;
 count = 1;
 ind = 1;
run;

/* Read in event-condition linking file */
FILENAME hc10if1 "C:\MEPS\hc10if1.ssp";
proc xcopy in = hc10if1 out = WORK IMPORT; run;
data clink1;
 set &syslast;
 keep DUPERSID CONDIDX EVNTIDX;
run;

FILENAME hc006r "C:\MEPS\hc006r.ssp";
proc xcopy in = hc006r out = WORK IMPORT; run;
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
 if condition in ("-1","-9","") or XP96X < 0 then delete;
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
 weight PERWT96F;
 var XP96X SF96X MR96X MD96X PR96X OZ96X;
 domain Condition;
run;
