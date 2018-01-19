ods graphics off;

/* Read in dataset and initialize year */
FILENAME h28 "C:\MEPS\h28.ssp";
proc xcopy in = h28 out = WORK IMPORT;
run;

data MEPS;
 SET h28;
 ARRAY OLDVAR(5) VARPSU98 VARSTR98 WTDPER98 AGE2X AGE1X;
 year = 1998;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU98;
  VARSTR = VARSTR98;
 end;

 if year <= 1998 then do;
  PERWT98F = WTDPER98;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE98X >= 0 then AGELAST = AGE98x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Source of payment */
data MEPS; set MEPS;
 ARRAY OLDSOP(1) TOTCHM98;
 if year <= 1999 then do;
  TOTTRI98 = TOTCHM98;
 end;

 TOTOTH98 = TOTOFD98 + TOTSTL98 + TOTOPR98 + TOTOPU98 + TOTOSR98;
   TOTOTZ98 = TOTOTH98 + TOTWCP98 + TOTVA98;
   TOTPTR98 = TOTPRV98 + TOTTRI98;
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
  year = 1998;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH98X &evnt.FCH98X SEEDOC ;
   SF98X = &evnt.DSF98X + &evnt.FSF98X;
   MR98X = &evnt.DMR98X + &evnt.FMR98X;
   MD98X = &evnt.DMD98X + &evnt.FMD98X;
   PV98X = &evnt.DPV98X + &evnt.FPV98X;
   VA98X = &evnt.DVA98X + &evnt.FVA98X;
   OF98X = &evnt.DOF98X + &evnt.FOF98X;
   SL98X = &evnt.DSL98X + &evnt.FSL98X;
   WC98X = &evnt.DWC98X + &evnt.FWC98X;
   OR98X = &evnt.DOR98X + &evnt.FOR98X;
   OU98X = &evnt.DOU98X + &evnt.FOU98X;
   OT98X = &evnt.DOT98X + &evnt.FOT98X;
   XP98X = &evnt.DXP98X + &evnt.FXP98X;

   if year <= 1999 then TR98X = &evnt.DCH98X + &evnt.FCH98X;
   else TR98X = &evnt.DTR98X + &evnt.FTR98X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH98X SEEDOC ;
   SF98X = &evnt.SF98X;
   MR98X = &evnt.MR98X;
   MD98X = &evnt.MD98X;
   PV98X = &evnt.PV98X;
   VA98X = &evnt.VA98X;
   OF98X = &evnt.OF98X;
   SL98X = &evnt.SL98X;
   WC98X = &evnt.WC98X;
   OR98X = &evnt.OR98X;
   OU98X = &evnt.OU98X;
   OT98X = &evnt.OT98X;
   XP98X = &evnt.XP98X;

   if year <= 1999 then TR98X = &evnt.CH98X;
   else TR98X = &evnt.TR98X;
  %end;

  PR98X = PV98X + TR98X;
  OZ98X = OF98X + SL98X + OT98X + OR98X + OU98X + WC98X + VA98X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP98X SF98X PR98X MR98X MD98X OZ98X;
 run;
%mend;

%load_events(RX,h26a);
%load_events(DV,hc26bf1);
%load_events(IP,h26df1);
%load_events(ER,h26ef1);
%load_events(OP,h26ff1);
%load_events(OB,h26gf1);
%load_events(HH,h26hf1);

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
 keep ind DUPERSID PERWT98F VARSTR VARPSU;
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
 var SF98X MR98X MD98X XP98X PR98X OZ98X;
 output out = RXpers sum = ;
run;

data stacked_events;
 set RXpers IP ER OP OB HH;
 where XP98X >= 0;
 count = 1;
 ind = 1;
run;

/* Read in event-condition linking file */
FILENAME h26if1 "C:\MEPS\h26if1.ssp";
proc xcopy in = h26if1 out = WORK IMPORT; run;
data clink1;
 set &syslast;
 keep DUPERSID CONDIDX EVNTIDX;
run;

FILENAME h27 "C:\MEPS\h27.ssp";
proc xcopy in = h27 out = WORK IMPORT; run;
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
 if condition in ("-1","-9","") or XP98X < 0 then delete;
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
 weight PERWT98F;
 var XP98X SF98X MR98X MD98X PR98X OZ98X;
 domain Condition;
run;
