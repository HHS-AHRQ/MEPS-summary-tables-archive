ods graphics off;

/* Read in dataset and initialize year */
FILENAME h171 "C:\MEPS\h171.ssp";
proc xcopy in = h171 out = WORK IMPORT;
run;

data MEPS;
 SET h171;
 ARRAY OLDVAR(5) VARPSU14 VARSTR14 WTDPER14 AGE2X AGE1X;
 year = 2014;
 ind = 1;
 count = 1;

 if year <= 2001 then do;
  VARPSU = VARPSU14;
  VARSTR = VARSTR14;
 end;

 if year <= 1998 then do;
  PERWT14F = WTDPER14;
 end;

 /* Create AGELAST variable */
 if year = 1996 then do;
   AGE42X = AGE2X;
   AGE31X = AGE1X;
 end;

 if AGE14X >= 0 then AGELAST = AGE14x;
 else if AGE42X >= 0 then AGELAST = AGE42X;
 else if AGE31X >= 0 then AGELAST = AGE31X;
run;

proc format;
 value ind 1 = "Total";
run;

/* Event type */
data MEPS; set MEPS;
 HHTEXP14 = HHAEXP14 + HHNEXP14; /* Home Health Agency + Independent providers */
 ERTEXP14 = ERFEXP14 + ERDEXP14; /* Doctor + Facility Expenses for OP, ER, IP events */
 IPTEXP14 = IPFEXP14 + IPDEXP14;
 OPTEXP14 = OPFEXP14 + OPDEXP14; /* All Outpatient */
 OPYEXP14 = OPVEXP14 + OPSEXP14; /* Physician only */
 OPZEXP14 = OPOEXP14 + OPPEXP14; /* non-physician only */
 OMAEXP14 = VISEXP14 + OTHEXP14;

 TOTUSE14 = 
  ((DVTOT14 > 0) + (RXTOT14 > 0) + (OBTOTV14 > 0) +
  (OPTOTV14 > 0) + (ERTOT14 > 0) + (IPDIS14 > 0) +
  (HHTOTD14 > 0) + (OMAEXP14 > 0));
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
  year = 2014;

  %if &evnt in (IP OP ER) %then %do;
  ARRAY OLDVARS2(3) &evnt.DCH14X &evnt.FCH14X SEEDOC ;
   SF14X = &evnt.DSF14X + &evnt.FSF14X;
   MR14X = &evnt.DMR14X + &evnt.FMR14X;
   MD14X = &evnt.DMD14X + &evnt.FMD14X;
   PV14X = &evnt.DPV14X + &evnt.FPV14X;
   VA14X = &evnt.DVA14X + &evnt.FVA14X;
   OF14X = &evnt.DOF14X + &evnt.FOF14X;
   SL14X = &evnt.DSL14X + &evnt.FSL14X;
   WC14X = &evnt.DWC14X + &evnt.FWC14X;
   OR14X = &evnt.DOR14X + &evnt.FOR14X;
   OU14X = &evnt.DOU14X + &evnt.FOU14X;
   OT14X = &evnt.DOT14X + &evnt.FOT14X;
   XP14X = &evnt.DXP14X + &evnt.FXP14X;

   if year <= 1999 then TR14X = &evnt.DCH14X + &evnt.FCH14X;
   else TR14X = &evnt.DTR14X + &evnt.FTR14X;
  %end;

  %else %do;
  ARRAY OLDVARS2(2) &evnt.CH14X SEEDOC ;
   SF14X = &evnt.SF14X;
   MR14X = &evnt.MR14X;
   MD14X = &evnt.MD14X;
   PV14X = &evnt.PV14X;
   VA14X = &evnt.VA14X;
   OF14X = &evnt.OF14X;
   SL14X = &evnt.SL14X;
   WC14X = &evnt.WC14X;
   OR14X = &evnt.OR14X;
   OU14X = &evnt.OU14X;
   OT14X = &evnt.OT14X;
   XP14X = &evnt.XP14X;

   if year <= 1999 then TR14X = &evnt.CH14X;
   else TR14X = &evnt.TR14X;
  %end;

  PR14X = PV14X + TR14X;
  OZ14X = OF14X + SL14X + OT14X + OR14X + OU14X + WC14X + VA14X;

  keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP14X SF14X PR14X MR14X MD14X OZ14X;
 run;
%mend;

%load_events(RX,h168a);
%load_events(DV,h168b);
%load_events(IP,h168d);
%load_events(ER,h168e);
%load_events(OP,h168f);
%load_events(OB,h168g);
%load_events(HH,h168h);

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
 keep ind DUPERSID PERWT14F VARSTR VARPSU;
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
 var SF14X MR14X MD14X XP14X PR14X OZ14X;
 output out = RXpers sum = ;
run;

data stacked_events;
 set RXpers IP ER OP OB HH;
 where XP14X >= 0;
 count = 1;
 ind = 1;
run;

/* Read in event-condition linking file */
FILENAME h168if1 "C:\MEPS\h168if1.ssp";
proc xcopy in = h168if1 out = WORK IMPORT; run;
data clink1;
 set &syslast;
 keep DUPERSID CONDIDX EVNTIDX;
run;

FILENAME h170 "C:\MEPS\h170.ssp";
proc xcopy in = h170 out = WORK IMPORT; run;
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
 if condition in ("-1","-9","") or XP14X < 0 then delete;
run;

proc sort data = FYCsub; by DUPERSID; run;
data all_events;
 merge event_cond FYCsub;
 by DUPERSID;
 count = 1;
 ind = 1;
run;

proc sort data = all_events;
 by ind DUPERSID VARSTR VARPSU PERWT14F Condition event ind count;
run;

proc means data = all_events noprint;
 by ind DUPERSID VARSTR VARPSU PERWT14F Condition event ind count;
 var SF14X MR14X MD14X XP14X PR14X OZ14X;
 output out = all_persev sum = ;
run;

ods output Domain = out;
proc surveymeans data = all_persev sum ;
 FORMAT ind ind.;
 stratum VARSTR;
 cluster VARPSU;
 weight PERWT14F;
 var XP14X;
 domain Condition*event ;
run;
