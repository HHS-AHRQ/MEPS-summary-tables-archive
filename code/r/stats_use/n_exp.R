list(
demo  = 'svyby(~(PERWT.yy.F > 0), FUN = unwtd.count, by = ~.by., design = subset(FYCdsgn, TOTEXP.yy. > 0))',

event = '
    events <- c("TOT", "DVT", "RX",  "OBV", "OBD", "OBO",
                "OPT", "OPY", "OPZ", "ERT", "IPT", "HHT", "OMA")

  results <- list()
  for(ev in events) {
    key <- paste0(ev, "EXP", ".yy.")
    results[[key]] <- svyby(~(PERWT.yy.F > 0), FUN = unwtd.count, by = ~.by., design = subset(FYCdsgn, FYC[[key]] > 0))
  }
  print(results)',

  sop   = '
  sops <- c("EXP", "SLF", "PTR", "MCR", "MCD", "OTZ")
  results <- list()

  for(sp in sops) {
    key <- paste0("TOT", sp, ".yy.")
    results[[key]] <- svyby(~(PERWT.yy.F > 0), FUN = unwtd.count, by = ~.by., design = subset(FYCdsgn, FYC[[key]] > 0))
  }

  print(results)',

  event_sop = '
  # Loop over events, sops
    events <- c("TOT", "DVT", "RX",  "OBV", "OBD", "OBO",
                "OPT", "OPY", "OPZ", "ERT", "IPT", "HHT", "OMA")

    sops <- c("EXP", "SLF", "PTR", "MCR", "MCD", "OTZ")

    results <- list()
    for(ev in events) {
      for(sp in sops) {
        key <- paste0(ev, sp, ".yy.")
        results[[key]] <- svyby(~(PERWT.yy.F > 0), FUN = unwtd.count, by = ~.by., design = subset(FYCdsgn, FYC[[key]] > 0))
      }
    }
    print(results)'

)
