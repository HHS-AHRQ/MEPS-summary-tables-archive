

ods graphics off;

options dkricond = warn;

/* Read in dataset and initialize year */
  FILENAME &RX. "C:\MEPS\&RX..ssp";
  proc xcopy in = &RX. out = WORK IMPORT;
  run;

  data RX;
    set &syslast;
    ARRAY OLDVAR(3) VARPSU&yy. VARSTR&yy. WTDPER&yy.;
    year = &year.;
    count = 1;

    if year <= 2001 then do;
      VARPSU = VARPSU&yy.;
      VARSTR = VARSTR&yy.;
    end;

    if year <= 1998 then do;
      PERWT&yy.F = WTDPER&yy.;
    end;

    domain = (RXNDC ne "-9");
  run;

/* For 1996-2013, merge with RX multum Lexicon Addendum files */
  %macro addMultum(year);
    %if &year <= 2013 %then %do;
      FILENAME &Multum. "C:\MEPS\&Multum..ssp";
      proc xcopy in = &Multum. out = WORK IMPORT;
      run;

      data Multum; set &syslast; run;

      proc sort data = Multum; by DUPERSID RXRECIDX; run;
      proc sort data = RX (drop = PREGCAT RXDRGNAM TC:) ;
        by DUPERSID RXRECIDX;
      run;

      data RX;
        merge RX Multum;
        by DUPERSID RXRECIDX;
      run;
    %end;
  %mend;

  %addMultum(&year.);

/* Format for therapeutic classes */
  proc format;
    value TC1name
    -9  ='Not ascertained                                        '
    -1  ='Inapplicable                                           '
     1  ='Anti-infectives                                        '
    19  ='Antihyperlipidemic agents                              '
    20  ='Antineoplastics                                        '
    28  ='Biologicals                                            '
    40  ='Cardiovascular agents                                  '
    57  ='Central nervous system agents                          '
    81  ='Coagulation modifiers                                  '
    87  ='Gastrointestinal agents                                '
    97  ='Hormones/hormone modifiers                             '
    105  ='Miscellaneous agents                                   '
    113  ='Genitourinary tract agents                             '
    115  ='Nutritional products                                   '
    122  ='Respiratory agents                                     '
    133  ='Topical agents                                         '
    218  ='Alternative medicines                                  '
    242  ='Psychotherapeutic agents                               '
    254  ='Immunologic agents                                     '
    358  ='Metabolic agents                                       '
    ;
  run;
;

ods output Domain = out;
proc surveymeans data = RX sum ;
  format TC1 TC1name.;
  stratum VARSTR;
  cluster VARPSU;
  weight PERWT&yy.F;
  var count;
  domain TC1;
run;

proc print data = out;
run;

