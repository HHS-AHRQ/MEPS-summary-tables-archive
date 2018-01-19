ods graphics off;

/* Read in dataset and initialize year */
FILENAME h138 "C:\MEPS\h138.ssp";
proc xcopy in = h138 out = WORK IMPORT;
run;

data MEPS;
 SET h138;
 ARRAY OLDVAR(5) VARPSU10 VARSTR10 WTDPER10 AGE2X AGE1X;
 year = 2010;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU10;
  VARSTR = VARSTR10;
 end;

 if year <= 1998 then do;
  PERWT10F = WTDPER10;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE10X >= 0 then AGELAST = AGE10x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Event type */
data MEPS; set MEPS;
 HHTEXP10 = HHAEXP10 + HHNEXP10; /* Home Health Agency + Independent providers */
 ERTEXP10 = ERFEXP10 + ERDEXP10; /* Doctor + Facility Expenses for OP, ER, IP events */
 IPTEXP10 = IPFEXP10 + IPDEXP10;
 OPTEXP10 = OPFEXP10 + OPDEXP10; /* All Outpatient */
 OPYEXP10 = OPVEXP10 + OPSEXP10; /* Physician only */
 OPZEXP10 = OPOEXP10 + OPPEXP10; /* non-physician only */
 OMAEXP10 = VISEXP10 + OTHEXP10;

 TOTUSE10 = 
  ((DVTOT10 > 0) + (RXTOT10 > 0) + (OBTOTV10 > 0) +
  (OPTOTV10 > 0) + (ERTOT10 > 0) + (IPDIS10 > 0) +
  (HHTOTD10 > 0) + (OMAEXP10 > 0));
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
  year = 2010;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH10X &evnt.FCH10X SEEDOC ;
   SF10X = &evnt.DSF10X + &evnt.FSF10X;
   MR10X = &evnt.DMR10X + &evnt.FMR10X;
   MD10X = &evnt.DMD10X + &evnt.FMD10X;
   PV10X = &evnt.DPV10X + &evnt.FPV10X;
   VA10X = &evnt.DVA10X + &evnt.FVA10X;
   OF10X = &evnt.DOF10X + &evnt.FOF10X;
   SL10X = &evnt.DSL10X + &evnt.FSL10X;
   WC10X = &evnt.DWC10X + &evnt.FWC10X;
   OR10X = &evnt.DOR10X + &evnt.FOR10X;
   OU10X = &evnt.DOU10X + &evnt.FOU10X;
   OT10X = &evnt.DOT10X + &evnt.FOT10X;
   XP10X = &evnt.DXP10X + &evnt.FXP10X;

   if year <= 1999 then TR10X = &evnt.DCH10X + &evnt.FCH10X;
   else TR10X = &evnt.DTR10X + &evnt.FTR10X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH10X SEEDOC ;
   SF10X = &evnt.SF10X;
   MR10X = &evnt.MR10X;
   MD10X = &evnt.MD10X;
   PV10X = &evnt.PV10X;
   VA10X = &evnt.VA10X;
   OF10X = &evnt.OF10X;
   SL10X = &evnt.SL10X;
   WC10X = &evnt.WC10X;
   OR10X = &evnt.OR10X;
   OU10X = &evnt.OU10X;
   OT10X = &evnt.OT10X;
   XP10X = &evnt.XP10X;

   if year <= 1999 then TR10X = &evnt.CH10X;
   else TR10X = &evnt.TR10X;
  %end;

  PR10X = PV10X + TR10X;
  OZ10X = OF10X + SL10X + OT10X + OR10X + OU10X + WC10X + VA10X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP10X SF10X PR10X MR10X MD10X OZ10X;
 run;
%mend;

%load_events(RX,h135a);
%load_events(DV,h135b);
%load_events(IP,h135d);
%load_events(ER,h135e);
%load_events(OP,h135f);
%load_events(OB,h135g);
%load_events(HH,h135h);

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
 keep ind DUPERSID PERWT10F VARSTR VARPSU;
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
 var SF10X MR10X MD10X XP10X PR10X OZ10X;
 output out = RXpers sum = ;
run;

data stacked_events;
 set RXpers IP ER OP OB HH;
 where XP10X >= 0;
 count = 1;
 ind = 1;
run;

/* Read in event-condition linking file */
FILENAME h135if1 "C:\MEPS\h135if1.ssp";
proc xcopy in = h135if1 out = WORK IMPORT; run;
data clink1;
 set &syslast;
 keep DUPERSID CONDIDX EVNTIDX;
run;

FILENAME h137 "C:\MEPS\h137.ssp";
proc xcopy in = h137 out = WORK IMPORT; run;
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
 if condition in ("-1","-9","") or XP10X < 0 then delete;
run;

proc sort data = FYCsub; by DUPERSID; run;
data all_events;
 merge event_cond FYCsub;
 by DUPERSID;
 count = 1;
 ind = 1;
run;

proc sort data = all_events;
 by ind DUPERSID VARSTR VARPSU PERWT10F Condition event ind count;
run;

proc means data = all_events noprint;
 by ind DUPERSID VARSTR VARPSU PERWT10F Condition event ind count;
 var SF10X MR10X MD10X XP10X PR10X OZ10X;
 output out = all_persev sum = ;
run;

ods output Domain = out;
proc surveymeans data = all_persev sum ;
 FORMAT ind ind.;
 stratum VARSTR;
 cluster VARPSU;
 weight PERWT10F;
 var count;
 domain Condition*event;
run;
