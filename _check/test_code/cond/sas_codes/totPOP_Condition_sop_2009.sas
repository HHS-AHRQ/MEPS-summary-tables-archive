ods graphics off;

/* Read in dataset and initialize year */
FILENAME h129 "C:\MEPS\h129.ssp";
proc xcopy in = h129 out = WORK IMPORT;
run;

data MEPS;
 SET h129;
 ARRAY OLDVAR(5) VARPSU09 VARSTR09 WTDPER09 AGE2X AGE1X;
 year = 2009;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU09;
  VARSTR = VARSTR09;
 end;

 if year <= 1998 then do;
  PERWT09F = WTDPER09;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE09X >= 0 then AGELAST = AGE09x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Source of payment */
data MEPS; set MEPS;
 ARRAY OLDSOP(1) TOTCHM09;
 if year <= 1999 then do;
  TOTTRI09 = TOTCHM09;
 end;

 TOTOTH09 = TOTOFD09 + TOTSTL09 + TOTOPR09 + TOTOPU09 + TOTOSR09;
   TOTOTZ09 = TOTOTH09 + TOTWCP09 + TOTVA09;
   TOTPTR09 = TOTPRV09 + TOTTRI09;
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
  year = 2009;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH09X &evnt.FCH09X SEEDOC ;
   SF09X = &evnt.DSF09X + &evnt.FSF09X;
   MR09X = &evnt.DMR09X + &evnt.FMR09X;
   MD09X = &evnt.DMD09X + &evnt.FMD09X;
   PV09X = &evnt.DPV09X + &evnt.FPV09X;
   VA09X = &evnt.DVA09X + &evnt.FVA09X;
   OF09X = &evnt.DOF09X + &evnt.FOF09X;
   SL09X = &evnt.DSL09X + &evnt.FSL09X;
   WC09X = &evnt.DWC09X + &evnt.FWC09X;
   OR09X = &evnt.DOR09X + &evnt.FOR09X;
   OU09X = &evnt.DOU09X + &evnt.FOU09X;
   OT09X = &evnt.DOT09X + &evnt.FOT09X;
   XP09X = &evnt.DXP09X + &evnt.FXP09X;

   if year <= 1999 then TR09X = &evnt.DCH09X + &evnt.FCH09X;
   else TR09X = &evnt.DTR09X + &evnt.FTR09X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH09X SEEDOC ;
   SF09X = &evnt.SF09X;
   MR09X = &evnt.MR09X;
   MD09X = &evnt.MD09X;
   PV09X = &evnt.PV09X;
   VA09X = &evnt.VA09X;
   OF09X = &evnt.OF09X;
   SL09X = &evnt.SL09X;
   WC09X = &evnt.WC09X;
   OR09X = &evnt.OR09X;
   OU09X = &evnt.OU09X;
   OT09X = &evnt.OT09X;
   XP09X = &evnt.XP09X;

   if year <= 1999 then TR09X = &evnt.CH09X;
   else TR09X = &evnt.TR09X;
  %end;

  PR09X = PV09X + TR09X;
  OZ09X = OF09X + SL09X + OT09X + OR09X + OU09X + WC09X + VA09X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP09X SF09X PR09X MR09X MD09X OZ09X;
 run;
%mend;

%load_events(RX,h126a);
%load_events(DV,h126b);
%load_events(IP,h126d);
%load_events(ER,h126e);
%load_events(OP,h126f);
%load_events(OB,h126g);
%load_events(HH,h126h);

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
 keep ind DUPERSID PERWT09F VARSTR VARPSU;
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
 var SF09X MR09X MD09X XP09X PR09X OZ09X;
 output out = RXpers sum = ;
run;

data stacked_events;
 set RXpers IP ER OP OB HH;
 where XP09X >= 0;
 count = 1;
 ind = 1;
run;

/* Read in event-condition linking file */
FILENAME h126if1 "C:\MEPS\h126if1.ssp";
proc xcopy in = h126if1 out = WORK IMPORT; run;
data clink1;
 set &syslast;
 keep DUPERSID CONDIDX EVNTIDX;
run;

FILENAME h128 "C:\MEPS\h128.ssp";
proc xcopy in = h128 out = WORK IMPORT; run;
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
 if condition in ("-1","-9","") or XP09X < 0 then delete;
run;

proc sort data = FYCsub; by DUPERSID; run;
data all_events;
 merge event_cond FYCsub;
 by DUPERSID;
 count = 1;
 ind = 1;
run;

proc sort data = all_events;
 by ind DUPERSID VARSTR VARPSU PERWT09F Condition ind count;
run;

proc means data = all_events noprint;
 by ind DUPERSID VARSTR VARPSU PERWT09F Condition ind count;
 var SF09X MR09X MD09X XP09X PR09X OZ09X;
 output out = all_pers sum = ;
run;

data persNA; set all_pers;
 array vars XP09X SF09X MR09X MD09X PR09X OZ09X;
 do over vars;
  if vars <= 0 then vars = 0; else vars = 1;
 end;
run;

ods output Domain = out;
proc surveymeans data = persNA sum ;
 FORMAT ind ind.;
 stratum VARSTR;
 cluster VARPSU;
 weight PERWT09F;
 var XP09X SF09X MR09X MD09X PR09X OZ09X;
 domain Condition;
run;
