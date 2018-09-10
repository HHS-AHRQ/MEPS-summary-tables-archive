ins_stats <- list(
  insurance = 'results <- svyby(~insurance, FUN = .FUN., by = ~.by., design = FYCdsgn)',
  ins_lt65  = 'results <- svyby(~insurance_v2X, FUN = .FUN., by = ~.by., design = subset(FYCdsgn, AGELAST < 65))',
  ins_ge65  = 'results <- svyby(~insurance_v2X, FUN = .FUN., by = ~.by., design = subset(FYCdsgn, AGELAST >= 65))'
)

list(
  totPOP = lapply(ins_stats, function(x) rsub(x, FUN = "svytotal")),
  pctPOP = lapply(ins_stats, function(x) rsub(x, FUN = "svymean")),
  n      = lapply(ins_stats, function(x) rsub(x, FUN = "unwtd.count"))
)
