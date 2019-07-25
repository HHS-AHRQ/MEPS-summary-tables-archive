list(
demo = 'results <- svyby(~TOTEXP.yy., FUN = svyquantile, by = ~.by., design = subset(FYCdsgn, TOTEXP.yy. > 0), quantiles=c(0.5), ci=T, method="constant")',

event = '
# Loop over event types
  events <- c("TOT", "DVT", "RX",  "OBV", "OBD",
              "OPT", "OPY", "ERT", "IPT", "HHT", "OMA")

  results <- list()
  for(ev in events) {
    key <- paste0(ev, "EXP", ".yy.")
    formula <- as.formula(sprintf("~%s", key))
    results[[key]] <- svyby(formula, FUN = svyquantile, by = ~.by., design = subset(FYCdsgn, FYC[[key]] > 0), quantiles=c(0.5), ci=T, method="constant")
  }
',

sop   = '
# Loop over sources of payment
  sops <- c("EXP", "SLF", "PTR", "MCR", "MCD", "OTZ")
  results <- list()

  for(sp in sops) {
    key <- paste0("TOT", sp, ".yy.")
    formula <- as.formula(sprintf("~%s", key))
    results[[key]] <- svyby(formula, FUN = svyquantile, by = ~.by., design = subset(FYCdsgn, FYC[[key]] > 0), quantiles=c(0.5), ci=T, method="constant")
  }
',

event_sop = '
# Loop over events, sops
  events <- c("TOT", "DVT", "RX",  "OBV", "OBD",
              "OPT", "OPY", "ERT", "IPT", "HHT", "OMA")

  sops <- c("EXP", "SLF", "PTR", "MCR", "MCD", "OTZ")

  results <- list()
  for(ev in events) {
    for(sp in sops) {
      key <- paste0(ev, sp, ".yy.")
      formula <- as.formula(sprintf("~%s", key))
      results[[key]] <- svyby(formula, FUN = svyquantile, by = ~.by., design = subset(FYCdsgn, FYC[[key]] > 0), quantiles=c(0.5), ci=T, method="constant")
    }
  }
'
)
