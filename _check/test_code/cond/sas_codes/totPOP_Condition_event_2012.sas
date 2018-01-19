ods graphics off;

/* Read in dataset and initialize year */
FILENAME h155 "C:\MEPS\h155.ssp";
proc xcopy in = h155 out = WORK IMPORT;
run;

data MEPS;
 SET h155;
 ARRAY OLDVAR(5) VARPSU12 VARSTR12 WTDPER12 AGE2X AGE1X;
 year = 2012;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU12;
  VARSTR = VARSTR12;
 end;

 if year <= 1998 then do;
  PERWT12F = WTDPER12;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE12X >= 0 then AGELAST = AGE12x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Event type */
data MEPS; set MEPS;
 HHTEXP12 = HHAEXP12 + HHNEXP12; /* Home Health Agency + Independent providers */
 ERTEXP12 = ERFEXP12 + ERDEXP12; /* Doctor + Facility Expenses for OP, ER, IP events */
 IPTEXP12 = IPFEXP12 + IPDEXP12;
 OPTEXP12 = OPFEXP12 + OPDEXP12; /* All Outpatient */
 OPYEXP12 = OPVEXP12 + OPSEXP12; /* Physician only */
 OPZEXP12 = OPOEXP12 + OPPEXP12; /* non-physician only */
 OMAEXP12 = VISEXP12 + OTHEXP12;

 TOTUSE12 = 
  ((DVTOT12 > 0) + (RXTOT12 > 0) + (OBTOTV12 > 0) +
  (OPTOTV12 > 0) + (ERTOT12 > 0) + (IPDIS12 > 0) +
  (HHTOTD12 > 0) + (OMAEXP12 > 0));
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
  year = 2012;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH12X &evnt.FCH12X SEEDOC ;
   SF12X = &evnt.DSF12X + &evnt.FSF12X;
   MR12X = &evnt.DMR12X + &evnt.FMR12X;
   MD12X = &evnt.DMD12X + &evnt.FMD12X;
   PV12X = &evnt.DPV12X + &evnt.FPV12X;
   VA12X = &evnt.DVA12X + &evnt.FVA12X;
   OF12X = &evnt.DOF12X + &evnt.FOF12X;
   SL12X = &evnt.DSL12X + &evnt.FSL12X;
   WC12X = &evnt.DWC12X + &evnt.FWC12X;
   OR12X = &evnt.DOR12X + &evnt.FOR12X;
   OU12X = &evnt.DOU12X + &evnt.FOU12X;
   OT12X = &evnt.DOT12X + &evnt.FOT12X;
   XP12X = &evnt.DXP12X + &evnt.FXP12X;

   if year <= 1999 then TR12X = &evnt.DCH12X + &evnt.FCH12X;
   else TR12X = &evnt.DTR12X + &evnt.FTR12X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH12X SEEDOC ;
   SF12X = &evnt.SF12X;
   MR12X = &evnt.MR12X;
   MD12X = &evnt.MD12X;
   PV12X = &evnt.PV12X;
   VA12X = &evnt.VA12X;
   OF12X = &evnt.OF12X;
   SL12X = &evnt.SL12X;
   WC12X = &evnt.WC12X;
   OR12X = &evnt.OR12X;
   OU12X = &evnt.OU12X;
   OT12X = &evnt.OT12X;
   XP12X = &evnt.XP12X;

   if year <= 1999 then TR12X = &evnt.CH12X;
   else TR12X = &evnt.TR12X;
  %end;

  PR12X = PV12X + TR12X;
  OZ12X = OF12X + SL12X + OT12X + OR12X + OU12X + WC12X + VA12X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP12X SF12X PR12X MR12X MD12X OZ12X;
 run;
%mend;

%load_events(RX,h152a);
%load_events(DV,h152b);
%load_events(IP,h152d);
%load_events(ER,h152e);
%load_events(OP,h152f);
%load_events(OB,h152g);
%load_events(HH,h152h);

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
 keep ind DUPERSID PERWT12F VARSTR VARPSU;
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
 var SF12X MR12X MD12X XP12X PR12X OZ12X;
 output out = RXpers sum = ;
run;

data stacked_events;
 set RXpers IP ER OP OB HH;
 where XP12X >= 0;
 count = 1;
 ind = 1;
run;

/* Read in event-condition linking file */
FILENAME h152if1 "C:\MEPS\h152if1.ssp";
proc xcopy in = h152if1 out = WORK IMPORT; run;
data clink1;
 set &syslast;
 keep DUPERSID CONDIDX EVNTIDX;
run;

FILENAME h154 "C:\MEPS\h154.ssp";
proc xcopy in = h154 out = WORK IMPORT; run;
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
 if condition in ("-1","-9","") or XP12X < 0 then delete;
run;

proc sort data = FYCsub; by DUPERSID; run;
data all_events;
 merge event_cond FYCsub;
 by DUPERSID;
 count = 1;
 ind = 1;
run;

proc sort data = all_events;
 by ind DUPERSID VARSTR VARPSU PERWT12F Condition event ind count;
run;

proc means data = all_events noprint;
 by ind DUPERSID VARSTR VARPSU PERWT12F Condition event ind count;
 var SF12X MR12X MD12X XP12X PR12X OZ12X;
 output out = all_persev sum = ;
run;

ods output Domain = out;
proc surveymeans data = all_persev sum ;
 FORMAT ind ind.;
 stratum VARSTR;
 cluster VARPSU;
 weight PERWT12F;
 var count;
 domain Condition*event;
run;
