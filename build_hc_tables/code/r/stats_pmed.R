list(
  totPOP = list(
    RXDRGNAM = 'results <- svyby(~count, by = ~RXDRGNAM, FUN = svytotal, design = DRGdsgn)',
    TC1name  = 'results <- svyby(~count, by = ~TC1name, FUN = svytotal, design = TC1dsgn)'
  ),
  totEXP = list(
    RXDRGNAM = 'results <- svyby(~RXXP.yy.X, by = ~RXDRGNAM, FUN = svytotal, design = subset(RXdsgn, RXNDC != "-9" & RXDRGNAM != "-9"))',
    TC1name  = 'results <- svyby(~RXXP.yy.X, by = ~TC1name, FUN = svytotal, design = RXdsgn)'
  ),
  totEVT = list(
    RXDRGNAM = 'results <- svyby(~count, by = ~RXDRGNAM, FUN = svytotal, design = subset(RXdsgn, RXNDC != "-9" & RXDRGNAM != "-9"))',
    TC1name  = 'results <- svyby(~count, by = ~TC1name, FUN = svytotal, design = RXdsgn)'
  ),
  n = list(
    RXDRGNAM = 'results <- svyby(~count, by = ~RXDRGNAM, FUN = unwtd.count, design = DRGdsgn)',
    TC1name  = 'results <- svyby(~count, by = ~TC1name, FUN = unwtd.count, design = TC1dsgn)'
  )
)
