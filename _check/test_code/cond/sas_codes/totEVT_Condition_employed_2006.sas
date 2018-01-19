ods graphics off;

/* Read in dataset and initialize year */
FILENAME h105 "C:\MEPS\h105.ssp";
proc xcopy in = h105 out = WORK IMPORT;
run;

data MEPS;
 SET h105;
 ARRAY OLDVAR(5) VARPSU06 VARSTR06 WTDPER06 AGE2X AGE1X;
 year = 2006;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU06;
  VARSTR = VARSTR06;
 end;

 if year <= 1998 then do;
  PERWT06F = WTDPER06;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE06X >= 0 then AGELAST = AGE06x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Employment Status */
data MEPS; set MEPS;
 ARRAY OLDEMP(3) EMPST1 EMPST2 EMPST96;
 if year = 1996 then do;
  EMPST53 = EMPST96;
  EMPST42 = EMPST2;
  EMPST31 = EMPST1;
 end;

 if EMPST53 >= 0 then employ_last = EMPST53;
 else if EMPST42 >= 0 then employ_last = EMPST42;
 else if EMPST31 >= 0 then employ_last = EMPST31;
 else employ_last = .;

 employed = 1*(employ_last = 1) + 2*(employ_last > 1);
 if employed < 1 and AGELAST < 16 then employed = 9;
run;

proc format;
 value employed
 1 = "Employed"
 2 = "Not employed"
 9 = "Inapplicable (age < 16)"
 . = "Missing"
 0 = "Missing";
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
  year = 2006;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH06X &evnt.FCH06X SEEDOC ;
   SF06X = &evnt.DSF06X + &evnt.FSF06X;
   MR06X = &evnt.DMR06X + &evnt.FMR06X;
   MD06X = &evnt.DMD06X + &evnt.FMD06X;
   PV06X = &evnt.DPV06X + &evnt.FPV06X;
   VA06X = &evnt.DVA06X + &evnt.FVA06X;
   OF06X = &evnt.DOF06X + &evnt.FOF06X;
   SL06X = &evnt.DSL06X + &evnt.FSL06X;
   WC06X = &evnt.DWC06X + &evnt.FWC06X;
   OR06X = &evnt.DOR06X + &evnt.FOR06X;
   OU06X = &evnt.DOU06X + &evnt.FOU06X;
   OT06X = &evnt.DOT06X + &evnt.FOT06X;
   XP06X = &evnt.DXP06X + &evnt.FXP06X;

   if year <= 1999 then TR06X = &evnt.DCH06X + &evnt.FCH06X;
   else TR06X = &evnt.DTR06X + &evnt.FTR06X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH06X SEEDOC ;
   SF06X = &evnt.SF06X;
   MR06X = &evnt.MR06X;
   MD06X = &evnt.MD06X;
   PV06X = &evnt.PV06X;
   VA06X = &evnt.VA06X;
   OF06X = &evnt.OF06X;
   SL06X = &evnt.SL06X;
   WC06X = &evnt.WC06X;
   OR06X = &evnt.OR06X;
   OU06X = &evnt.OU06X;
   OT06X = &evnt.OT06X;
   XP06X = &evnt.XP06X;

   if year <= 1999 then TR06X = &evnt.CH06X;
   else TR06X = &evnt.TR06X;
  %end;

  PR06X = PV06X + TR06X;
  OZ06X = OF06X + SL06X + OT06X + OR06X + OU06X + WC06X + VA06X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP06X SF06X PR06X MR06X MD06X OZ06X;
 run;
%mend;

%load_events(RX,h102a);
%load_events(DV,h102b);
%load_events(IP,h102d);
%load_events(ER,h102e);
%load_events(OP,h102f);
%load_events(OB,h102g);
%load_events(HH,h102h);

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
 keep employed DUPERSID PERWT06F VARSTR VARPSU;
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
 var SF06X MR06X MD06X XP06X PR06X OZ06X;
 output out = RXpers sum = ;
run;

data stacked_events;
 set RXpers IP ER OP OB HH;
 where XP06X >= 0;
 count = 1;
 ind = 1;
run;

/* Read in event-condition linking file */
FILENAME h102if1 "C:\MEPS\h102if1.ssp";
proc xcopy in = h102if1 out = WORK IMPORT; run;
data clink1;
 set &syslast;
 keep DUPERSID CONDIDX EVNTIDX;
run;

FILENAME h104 "C:\MEPS\h104.ssp";
proc xcopy in = h104 out = WORK IMPORT; run;
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
 if condition in ("-1","-9","") or XP06X < 0 then delete;
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
 FORMAT employed employed.;
 stratum VARSTR;
 cluster VARPSU;
 weight PERWT06F;
 var count;
 domain Condition*employed ;
run;
