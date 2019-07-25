list(
demo  = 'results <- svyby(~(PERWT.yy.F > 0), FUN = unwtd.count, by = ~.by., design = subset(FYCdsgn, PERWT.yy.F > 0))',

event = '
  events <- c("TOTUSE", "DVTOT", "RXTOT", "OBTOTV", "OBDRV",
              "OPTOTV", "OPDRV", "ERTOT", "IPDIS", "HHTOTD", "OMAEXP")

  results <- list()
  for(ev in events) {
    key <- sprintf("%s.yy.", ev)
    formula <- as.formula(sprintf("~(%s > 0)", key))
    results[[key]] <- svyby(formula, FUN = unwtd.count, by = ~.by., design = subset(FYCdsgn, FYC[[key]] > 0))
  }
',

sop   = '
# Loop over sources of payment
  sops <- c("EXP", "SLF", "PTR", "MCR", "MCD", "OTZ")
  results <- list()

  for(sp in sops) {
    key <- paste0("TOT", sp, ".yy.")
    formula <- as.formula(sprintf("~(%s > 0)", key))
    results[[key]] <- svyby(formula, FUN = unwtd.count, by = ~.by., design = subset(FYCdsgn, FYC[[key]] > 0))
  }
',

event_sop = '
  events <- c("TOT", "DVT", "RX",  "OBV", "OBD",
              "OPT", "OPY", "ERT", "IPT", "HHT", "OMA")

  sops <- c("EXP", "SLF", "PTR", "MCR", "MCD", "OTZ")

  results <- list()
  for(ev in events) {
    for(sp in sops) {
      key <- paste0(ev, sp, ".yy.")
      formula <- as.formula(sprintf("~(%s > 0)", key))
      results[[key]] <- svyby(formula, FUN = unwtd.count, by = ~.by., design = subset(FYCdsgn, FYC[[key]] > 0))
    }
  }
  '
)
