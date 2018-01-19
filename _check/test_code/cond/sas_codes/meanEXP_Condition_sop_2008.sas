ods graphics off;

/* Read in dataset and initialize year */
FILENAME h121 "C:\MEPS\h121.ssp";
proc xcopy in = h121 out = WORK IMPORT;
run;

data MEPS;
 SET h121;
 ARRAY OLDVAR(5) VARPSU08 VARSTR08 WTDPER08 AGE2X AGE1X;
 year = 2008;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU08;
  VARSTR = VARSTR08;
 end;

 if year <= 1998 then do;
  PERWT08F = WTDPER08;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE08X >= 0 then AGELAST = AGE08x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Source of payment */
data MEPS; set MEPS;
 ARRAY OLDSOP(1) TOTCHM08;
 if year <= 1999 then do;
  TOTTRI08 = TOTCHM08;
 end;

 TOTOTH08 = TOTOFD08 + TOTSTL08 + TOTOPR08 + TOTOPU08 + TOTOSR08;
   TOTOTZ08 = TOTOTH08 + TOTWCP08 + TOTVA08;
   TOTPTR08 = TOTPRV08 + TOTTRI08;
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
  year = 2008;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH08X &evnt.FCH08X SEEDOC ;
   SF08X = &evnt.DSF08X + &evnt.FSF08X;
   MR08X = &evnt.DMR08X + &evnt.FMR08X;
   MD08X = &evnt.DMD08X + &evnt.FMD08X;
   PV08X = &evnt.DPV08X + &evnt.FPV08X;
   VA08X = &evnt.DVA08X + &evnt.FVA08X;
   OF08X = &evnt.DOF08X + &evnt.FOF08X;
   SL08X = &evnt.DSL08X + &evnt.FSL08X;
   WC08X = &evnt.DWC08X + &evnt.FWC08X;
   OR08X = &evnt.DOR08X + &evnt.FOR08X;
   OU08X = &evnt.DOU08X + &evnt.FOU08X;
   OT08X = &evnt.DOT08X + &evnt.FOT08X;
   XP08X = &evnt.DXP08X + &evnt.FXP08X;

   if year <= 1999 then TR08X = &evnt.DCH08X + &evnt.FCH08X;
   else TR08X = &evnt.DTR08X + &evnt.FTR08X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH08X SEEDOC ;
   SF08X = &evnt.SF08X;
   MR08X = &evnt.MR08X;
   MD08X = &evnt.MD08X;
   PV08X = &evnt.PV08X;
   VA08X = &evnt.VA08X;
   OF08X = &evnt.OF08X;
   SL08X = &evnt.SL08X;
   WC08X = &evnt.WC08X;
   OR08X = &evnt.OR08X;
   OU08X = &evnt.OU08X;
   OT08X = &evnt.OT08X;
   XP08X = &evnt.XP08X;

   if year <= 1999 then TR08X = &evnt.CH08X;
   else TR08X = &evnt.TR08X;
  %end;

  PR08X = PV08X + TR08X;
  OZ08X = OF08X + SL08X + OT08X + OR08X + OU08X + WC08X + VA08X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP08X SF08X PR08X MR08X MD08X OZ08X;
 run;
%mend;

%load_events(RX,h118a);
%load_events(DV,h118b);
%load_events(IP,h118d);
%load_events(ER,h118e);
%load_events(OP,h118f);
%load_events(OB,h118g);
%load_events(HH,h118h);

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
 keep ind DUPERSID PERWT08F VARSTR VARPSU;
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
 var SF08X MR08X MD08X XP08X PR08X OZ08X;
 output out = RXpers sum = ;
run;

data stacked_events;
 set RXpers IP ER OP OB HH;
 where XP08X >= 0;
 count = 1;
 ind = 1;
run;

/* Read in event-condition linking file */
FILENAME h118if1 "C:\MEPS\h118if1.ssp";
proc xcopy in = h118if1 out = WORK IMPORT; run;
data clink1;
 set &syslast;
 keep DUPERSID CONDIDX EVNTIDX;
run;

FILENAME h120 "C:\MEPS\h120.ssp";
proc xcopy in = h120 out = WORK IMPORT; run;
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
 if condition in ("-1","-9","") or XP08X < 0 then delete;
run;

proc sort data = FYCsub; by DUPERSID; run;
data all_events;
 merge event_cond FYCsub;
 by DUPERSID;
 count = 1;
 ind = 1;
run;

proc sort data = all_events;
 by ind DUPERSID VARSTR VARPSU PERWT08F Condition ind count;
run;

proc means data = all_events noprint;
 by ind DUPERSID VARSTR VARPSU PERWT08F Condition ind count;
 var SF08X MR08X MD08X XP08X PR08X OZ08X;
 output out = all_pers sum = ;
run;

ods output Domain = out;
proc surveymeans data = all_pers mean ;
 FORMAT ind ind.;
 stratum VARSTR;
 cluster VARPSU;
 weight PERWT08F;
 var XP08X SF08X MR08X MD08X PR08X OZ08X;
 domain Condition;
run;
