
* Define formats for CCS codes to collapsed conditions ***********************;

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

* Macro to load event files **************************************************;

  %macro load_events(evnt,file) / minoperator;

    FILENAME &file. "C:\MEPS\&file..ssp";
    proc xcopy in = &file. out = WORK IMPORT;
    run;

    data &evnt;
      SET &syslast; /* Most recent dataset loaded */
      ARRAY OLDVARS(2) LINKIDX EVNTIDX;
      event = "&evnt.";
      year = &year.;

      %if &evnt in (IP OP ER) %then %do;
      ARRAY OLDVARS2(3) &evnt.DCH&yy.X &evnt.FCH&yy.X SEEDOC ;
        SF&yy.X = &evnt.DSF&yy.X + &evnt.FSF&yy.X;
        MR&yy.X = &evnt.DMR&yy.X + &evnt.FMR&yy.X;
        MD&yy.X = &evnt.DMD&yy.X + &evnt.FMD&yy.X;
        PV&yy.X = &evnt.DPV&yy.X + &evnt.FPV&yy.X;
        VA&yy.X = &evnt.DVA&yy.X + &evnt.FVA&yy.X;
        OF&yy.X = &evnt.DOF&yy.X + &evnt.FOF&yy.X;
        SL&yy.X = &evnt.DSL&yy.X + &evnt.FSL&yy.X;
        WC&yy.X = &evnt.DWC&yy.X + &evnt.FWC&yy.X;
        OR&yy.X = &evnt.DOR&yy.X + &evnt.FOR&yy.X;
        OU&yy.X = &evnt.DOU&yy.X + &evnt.FOU&yy.X;
        OT&yy.X = &evnt.DOT&yy.X + &evnt.FOT&yy.X;
        XP&yy.X = &evnt.DXP&yy.X + &evnt.FXP&yy.X;

        if year <= 1999 then TR&yy.X = &evnt.DCH&yy.X + &evnt.FCH&yy.X;
        else TR&yy.X = &evnt.DTR&yy.X + &evnt.FTR&yy.X;
      %end;

      %else %do;
      ARRAY OLDVARS2(2) &evnt.CH&yy.X SEEDOC ;
        SF&yy.X = &evnt.SF&yy.X;
        MR&yy.X = &evnt.MR&yy.X;
        MD&yy.X = &evnt.MD&yy.X;
        PV&yy.X = &evnt.PV&yy.X;
        VA&yy.X = &evnt.VA&yy.X;
        OF&yy.X = &evnt.OF&yy.X;
        SL&yy.X = &evnt.SL&yy.X;
        WC&yy.X = &evnt.WC&yy.X;
        OR&yy.X = &evnt.OR&yy.X;
        OU&yy.X = &evnt.OU&yy.X;
        OT&yy.X = &evnt.OT&yy.X;
        XP&yy.X = &evnt.XP&yy.X;

        if year <= 1999 then TR&yy.X = &evnt.CH&yy.X;
        else TR&yy.X = &evnt.TR&yy.X;
      %end;

      PR&yy.X = PV&yy.X + TR&yy.X;
      OZ&yy.X = OF&yy.X + SL&yy.X + OT&yy.X + OR&yy.X + OU&yy.X + WC&yy.X + VA&yy.X;

      keep DUPERSID LINKIDX EVNTIDX event SEEDOC XP&yy.X SF&yy.X PR&yy.X MR&yy.X MD&yy.X OZ&yy.X;
    run;
  %mend;

ods graphics off;

/* Read in FYC dataset and initialize year */
  FILENAME &FYC. "C:\MEPS\&FYC..ssp";
  proc xcopy in = &FYC. out = WORK IMPORT;
  run;

  data MEPS;
    SET &FYC.;
    ARRAY OLDVAR(5) VARPSU&yy. VARSTR&yy. WTDPER&yy. AGE2X AGE1X;
    year = &year.;
    ind = 1;
    count = 1;

    if year <= 2001 then do;
      VARPSU = VARPSU&yy.;
      VARSTR = VARSTR&yy.;
    end;

    if year <= 1998 then do;
      PERWT&yy.F = WTDPER&yy.;
    end;

    /* Create AGELAST variable */
    if year = 1996 then do;
      AGE42X = AGE2X;
      AGE31X = AGE1X;
    end;

    if AGE&yy.X >= 0 then AGELAST = AGE&yy.x;
    else if AGE42X >= 0 then AGELAST = AGE42X;
    else if AGE31X >= 0 then AGELAST = AGE31X;
  run;

  proc format;
    value ind 1 = "Total";
  run;

* Load and stack event files *************************************************;

/* Load event files */
  %load_events(RX,&RX.);
  %load_events(IP,&IP.);
  %load_events(ER,&ER.);
  %load_events(OP,&OP.);
  %load_events(OB,&OB.);
  %load_events(HH,&HH.);

/* Stack events */
  data RX; set RX;
    EVNTIDX = LINKIDX;
  run;

  data stacked_events;
    set RX IP ER OP OB HH;
    where XP&yy.X >= 0;
    count = 1;
    n_XP = (XP&yy.X > 0);
    n_SF = (SF&yy.X > 0);
    n_MR = (MR&yy.X > 0);
    n_MD = (MD&yy.X > 0);
    n_PR = (PR&yy.X > 0);
    n_OZ = (OZ&yy.X > 0);
  run;

* Read and merge conditions-CLINK files **************************************;

/* Read in event-condition linking file */
  FILENAME &CLNK. "C:\MEPS\&CLNK..ssp";
  proc xcopy in = &CLNK. out = WORK IMPORT; run;
  data clink1;
    set &syslast;
    keep DUPERSID CONDIDX EVNTIDX;
  run;

/* Read in conditions file */
  FILENAME &Conditions. "C:\MEPS\&Conditions..ssp";
  proc xcopy in = &Conditions. out = WORK IMPORT; run;
  data Conditions;
    set &syslast;
    keep DUPERSID CONDIDX CCCODEX condition;
    CCS_code = CCCODEX*1;
    condition = PUT(CCS_code, CCCFMT.);
  run;

/* Merge Conditions and CLINK files */
  proc sort data = clink1; by DUPERSID CONDIDX; run;
  proc sort data = conditions; by DUPERSID CONDIDX; run;
  data cond;
    merge clink1 conditions;
    by DUPERSID CONDIDX;
  run;

* Merge stacked events with Conditions file **********************************;

/* Count events for each EVNTIDX (can have multiple RX) */
/* A single EVNTIDX row is needed for correct merging   */
  proc sort data = stacked_events; by event DUPERSID EVNTIDX; run;
  proc means data = stacked_events noprint;
    by event DUPERSID EVNTIDX;
    var count SF&yy.X MR&yy.X MD&yy.X XP&yy.X PR&yy.X OZ&yy.X n_: ;
    output out = n_events sum = ;
  run;

/* Merge n_events with Conditions-CLINK file */
  proc sort data = cond nodupkey; by DUPERSID EVNTIDX condition; run;
  proc sort data = n_events; by DUPERSID EVNTIDX; run;
  data event_cond;
    merge n_events cond;
    by DUPERSID EVNTIDX;
    if condition in ("-1","-9","") or XP&yy.X < 0 then delete;
  run;

* Merge with FYC file ********************************************************;
  data FYCsub; set MEPS;
    keep ind DUPERSID PERWT&yy.F VARSTR VARPSU;
  run;

  proc sort data = FYCsub; by DUPERSID; run;
  data all_events;
    merge event_cond FYCsub;
    by DUPERSID;
    ind = 1;
  run;

* Mean expenditure per person ************************************************;

  /* Sum expenditures by person */
    proc sort data = all_events;
      by ind DUPERSID VARSTR VARPSU PERWT&yy.F Condition ind;
    run;

    proc means data = all_events noprint;
      by ind DUPERSID VARSTR VARPSU PERWT&yy.F Condition ind;
      var SF&yy.X MR&yy.X MD&yy.X XP&yy.X PR&yy.X OZ&yy.X;
      output out = all_pers sum = ;
    run;

  ods output Domain = out;
  proc surveymeans data = all_pers mean ;
    FORMAT ind ind.;
    stratum VARSTR;
    cluster VARPSU;
    weight PERWT&yy.F;
    var XP&yy.X SF&yy.X MR&yy.X MD&yy.X PR&yy.X OZ&yy.X;
    domain Condition;
  run;

