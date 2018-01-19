ods graphics off;

/* Read in dataset and initialize year */
FILENAME h50 "C:\MEPS\h50.ssp";
proc xcopy in = h50 out = WORK IMPORT;
run;

data MEPS;
 SET h50;
 ARRAY OLDVAR(5) VARPSU00 VARSTR00 WTDPER00 AGE2X AGE1X;
 year = 2000;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU00;
  VARSTR = VARSTR00;
 end;

 if year <= 1998 then do;
  PERWT00F = WTDPER00;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE00X >= 0 then AGELAST = AGE00x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Event type */
data MEPS; set MEPS;
 HHTEXP00 = HHAEXP00 + HHNEXP00; /* Home Health Agency + Independent providers */
 ERTEXP00 = ERFEXP00 + ERDEXP00; /* Doctor + Facility Expenses for OP, ER, IP events */
 IPTEXP00 = IPFEXP00 + IPDEXP00;
 OPTEXP00 = OPFEXP00 + OPDEXP00; /* All Outpatient */
 OPYEXP00 = OPVEXP00 + OPSEXP00; /* Physician only */
 OPZEXP00 = OPOEXP00 + OPPEXP00; /* non-physician only */
 OMAEXP00 = VISEXP00 + OTHEXP00;

 TOTUSE00 = 
  ((DVTOT00 > 0) + (RXTOT00 > 0) + (OBTOTV00 > 0) +
  (OPTOTV00 > 0) + (ERTOT00 > 0) + (IPDIS00 > 0) +
  (HHTOTD00 > 0) + (OMAEXP00 > 0));
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
  year = 2000;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH00X &evnt.FCH00X SEEDOC ;
   SF00X = &evnt.DSF00X + &evnt.FSF00X;
   MR00X = &evnt.DMR00X + &evnt.FMR00X;
   MD00X = &evnt.DMD00X + &evnt.FMD00X;
   PV00X = &evnt.DPV00X + &evnt.FPV00X;
   VA00X = &evnt.DVA00X + &evnt.FVA00X;
   OF00X = &evnt.DOF00X + &evnt.FOF00X;
   SL00X = &evnt.DSL00X + &evnt.FSL00X;
   WC00X = &evnt.DWC00X + &evnt.FWC00X;
   OR00X = &evnt.DOR00X + &evnt.FOR00X;
   OU00X = &evnt.DOU00X + &evnt.FOU00X;
   OT00X = &evnt.DOT00X + &evnt.FOT00X;
   XP00X = &evnt.DXP00X + &evnt.FXP00X;

   if year <= 1999 then TR00X = &evnt.DCH00X + &evnt.FCH00X;
   else TR00X = &evnt.DTR00X + &evnt.FTR00X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH00X SEEDOC ;
   SF00X = &evnt.SF00X;
   MR00X = &evnt.MR00X;
   MD00X = &evnt.MD00X;
   PV00X = &evnt.PV00X;
   VA00X = &evnt.VA00X;
   OF00X = &evnt.OF00X;
   SL00X = &evnt.SL00X;
   WC00X = &evnt.WC00X;
   OR00X = &evnt.OR00X;
   OU00X = &evnt.OU00X;
   OT00X = &evnt.OT00X;
   XP00X = &evnt.XP00X;

   if year <= 1999 then TR00X = &evnt.CH00X;
   else TR00X = &evnt.TR00X;
  %end;

  PR00X = PV00X + TR00X;
  OZ00X = OF00X + SL00X + OT00X + OR00X + OU00X + WC00X + VA00X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP00X SF00X PR00X MR00X MD00X OZ00X;
 run;
%mend;

%load_events(RX,h51a);
%load_events(DV,h51b);
%load_events(IP,h51d);
%load_events(ER,h51e);
%load_events(OP,h51f);
%load_events(OB,h51g);
%load_events(HH,h51h);

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
 keep ind DUPERSID PERWT00F VARSTR VARPSU;
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
 var SF00X MR00X MD00X XP00X PR00X OZ00X;
 output out = RXpers sum = ;
run;

data stacked_events;
 set RXpers IP ER OP OB HH;
 where XP00X >= 0;
 count = 1;
 ind = 1;
run;

/* Read in event-condition linking file */
FILENAME h51if1 "C:\MEPS\h51if1.ssp";
proc xcopy in = h51if1 out = WORK IMPORT; run;
data clink1;
 set &syslast;
 keep DUPERSID CONDIDX EVNTIDX;
run;

FILENAME h52 "C:\MEPS\h52.ssp";
proc xcopy in = h52 out = WORK IMPORT; run;
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
 if condition in ("-1","-9","") or XP00X < 0 then delete;
run;

proc sort data = FYCsub; by DUPERSID; run;
data all_events;
 merge event_cond FYCsub;
 by DUPERSID;
 count = 1;
 ind = 1;
run;

proc sort data = all_events;
 by ind DUPERSID VARSTR VARPSU PERWT00F Condition event ind count;
run;

proc means data = all_events noprint;
 by ind DUPERSID VARSTR VARPSU PERWT00F Condition event ind count;
 var SF00X MR00X MD00X XP00X PR00X OZ00X;
 output out = all_persev sum = ;
run;

ods output Domain = out;
proc surveymeans data = all_persev mean ;
 FORMAT ind ind.;
 stratum VARSTR;
 cluster VARPSU;
 weight PERWT00F;
 var XP00X;
 domain Condition*event ;
run;
