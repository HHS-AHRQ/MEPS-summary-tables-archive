ods graphics off;

/* Read in dataset and initialize year */
FILENAME h147 "C:\MEPS\h147.ssp";
proc xcopy in = h147 out = WORK IMPORT;
run;

data MEPS;
 SET h147;
 ARRAY OLDVAR(5) VARPSU11 VARSTR11 WTDPER11 AGE2X AGE1X;
 year = 2011;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU11;
  VARSTR = VARSTR11;
 end;

 if year <= 1998 then do;
  PERWT11F = WTDPER11;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE11X >= 0 then AGELAST = AGE11x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Source of payment */
data MEPS; set MEPS;
 ARRAY OLDSOP(1) TOTCHM11;
 if year <= 1999 then do;
  TOTTRI11 = TOTCHM11;
 end;

 TOTOTH11 = TOTOFD11 + TOTSTL11 + TOTOPR11 + TOTOPU11 + TOTOSR11;
   TOTOTZ11 = TOTOTH11 + TOTWCP11 + TOTVA11;
   TOTPTR11 = TOTPRV11 + TOTTRI11;
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
  year = 2011;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH11X &evnt.FCH11X SEEDOC ;
   SF11X = &evnt.DSF11X + &evnt.FSF11X;
   MR11X = &evnt.DMR11X + &evnt.FMR11X;
   MD11X = &evnt.DMD11X + &evnt.FMD11X;
   PV11X = &evnt.DPV11X + &evnt.FPV11X;
   VA11X = &evnt.DVA11X + &evnt.FVA11X;
   OF11X = &evnt.DOF11X + &evnt.FOF11X;
   SL11X = &evnt.DSL11X + &evnt.FSL11X;
   WC11X = &evnt.DWC11X + &evnt.FWC11X;
   OR11X = &evnt.DOR11X + &evnt.FOR11X;
   OU11X = &evnt.DOU11X + &evnt.FOU11X;
   OT11X = &evnt.DOT11X + &evnt.FOT11X;
   XP11X = &evnt.DXP11X + &evnt.FXP11X;

   if year <= 1999 then TR11X = &evnt.DCH11X + &evnt.FCH11X;
   else TR11X = &evnt.DTR11X + &evnt.FTR11X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH11X SEEDOC ;
   SF11X = &evnt.SF11X;
   MR11X = &evnt.MR11X;
   MD11X = &evnt.MD11X;
   PV11X = &evnt.PV11X;
   VA11X = &evnt.VA11X;
   OF11X = &evnt.OF11X;
   SL11X = &evnt.SL11X;
   WC11X = &evnt.WC11X;
   OR11X = &evnt.OR11X;
   OU11X = &evnt.OU11X;
   OT11X = &evnt.OT11X;
   XP11X = &evnt.XP11X;

   if year <= 1999 then TR11X = &evnt.CH11X;
   else TR11X = &evnt.TR11X;
  %end;

  PR11X = PV11X + TR11X;
  OZ11X = OF11X + SL11X + OT11X + OR11X + OU11X + WC11X + VA11X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP11X SF11X PR11X MR11X MD11X OZ11X;
 run;
%mend;

%load_events(RX,h144a);
%load_events(DV,h144b);
%load_events(IP,h144d);
%load_events(ER,h144e);
%load_events(OP,h144f);
%load_events(OB,h144g);
%load_events(HH,h144h);

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
 keep ind DUPERSID PERWT11F VARSTR VARPSU;
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
 var SF11X MR11X MD11X XP11X PR11X OZ11X;
 output out = RXpers sum = ;
run;

data stacked_events;
 set RXpers IP ER OP OB HH;
 where XP11X >= 0;
 count = 1;
 ind = 1;
run;

/* Read in event-condition linking file */
FILENAME h144if1 "C:\MEPS\h144if1.ssp";
proc xcopy in = h144if1 out = WORK IMPORT; run;
data clink1;
 set &syslast;
 keep DUPERSID CONDIDX EVNTIDX;
run;

FILENAME h146 "C:\MEPS\h146.ssp";
proc xcopy in = h146 out = WORK IMPORT; run;
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
 if condition in ("-1","-9","") or XP11X < 0 then delete;
run;

proc sort data = FYCsub; by DUPERSID; run;
data all_events;
 merge event_cond FYCsub;
 by DUPERSID;
 count = 1;
 ind = 1;
run;

proc sort data = all_events;
 by ind DUPERSID VARSTR VARPSU PERWT11F Condition ind count;
run;

proc means data = all_events noprint;
 by ind DUPERSID VARSTR VARPSU PERWT11F Condition ind count;
 var SF11X MR11X MD11X XP11X PR11X OZ11X;
 output out = all_pers sum = ;
run;

ods output Domain = out;
proc surveymeans data = all_pers mean ;
 FORMAT ind ind.;
 stratum VARSTR;
 cluster VARPSU;
 weight PERWT11F;
 var XP11X SF11X MR11X MD11X PR11X OZ11X;
 domain Condition;
run;
