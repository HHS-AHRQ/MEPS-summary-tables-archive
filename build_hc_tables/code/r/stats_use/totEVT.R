list(
demo  = 'results <- svyby(~(XP.yy.X >= 0), FUN=svytotal, by = ~.by., design = subset(EVNTdsgn, XP.yy.X >= 0))',

event = 'results <- svyby(~(XP.yy.X >= 0), FUN=svytotal, by = ~.by. + event, design = subset(EVNTdsgn, XP.yy.X >= 0))',

sop   = '
# Loop over sources of payment
  sops <- c("XP", "SF", "PR", "MR", "MD", "OZ")
  results <- list()
  for(sp in sops) {
    key <- paste0(sp, ".yy.X")
    formula <- as.formula(sprintf("~(%s > 0)", key))
    results[[key]] <- svyby(formula, FUN = svytotal, by = ~.by.,
      design = subset(EVNTdsgn, EVENTS[[key]] >= 0))
  }
',

event_sop   = '
# Loop over sources of payment
  sops <- c("XP", "SF", "PR", "MR", "MD", "OZ")
  results <- list()
  for(sp in sops) {
    key <- paste0(sp, ".yy.X")
    formula <- as.formula(sprintf("~(%s > 0)", key))
    results[[key]] <- svyby(formula, FUN = svytotal, by = ~.by. + event,
      design = subset(EVNTdsgn, EVENTS[[key]] >= 0))
  }
'
)
