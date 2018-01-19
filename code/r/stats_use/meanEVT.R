list(
demo  = 'svyby(~XP.yy.X, FUN=svymean, by = ~.by., design = subset(EVNTdsgn, XP.yy.X >= 0))',

event = 'svyby(~XP.yy.X, FUN=svymean, by = ~.by. + event, design = subset(EVNTdsgn, XP.yy.X >= 0))',

sop = '
# Loop over sources of payment
  sops <- c("XP", "SF", "PR", "MR", "MD", "OZ")
  results <- list()
  for(sp in sops) {
    key <- paste0(sp, ".yy.X")
    formula <- as.formula(sprintf("~%s", key))
    results[[key]] <- svyby(formula, FUN = svymean, by = ~.by.,
      design = subset(EVNTdsgn, EVENTS[[key]] >= 0))
  }

  print(results)',

event_sop = '
# Loop over sources of payment
  sops <- c("XP", "SF", "PR", "MR", "MD", "OZ")
  results <- list()
  for(sp in sops) {
    key <- paste0(sp, ".yy.X")
    formula <- as.formula(sprintf("~%s", key))
    results[[key]] <- svyby(formula, FUN = svymean, by = ~.by. + event,
      design = subset(EVNTdsgn, EVENTS[[key]] >= 0))
  }
  print(results)'

)
