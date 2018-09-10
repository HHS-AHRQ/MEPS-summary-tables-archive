

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

proc sort data = RX;
  by DUPERSID VARSTR VARPSU PERWT&yy.F RXDRGNAM;
run;

proc means data = RX noprint;
  where domain = 1;
  by DUPERSID VARSTR VARPSU PERWT&yy.F RXDRGNAM;
  var count;
  output out = DRGpers mean = ind;
run;

ods output Domain = out;
proc surveymeans data = DRGpers sum ;
  stratum VARSTR;
  cluster VARPSU;
  weight PERWT&yy.F;
  var ind;
  domain RXDRGNAM;
run;

proc print data = out;
run;

