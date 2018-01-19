# Sum by person, condition, across event
all_pers <- all_events %>%
  group_by(.subgrps., DUPERSID, VARSTR, VARPSU, PERWT.yy.F, Condition, count) %>%
  summarize_at(vars(SF.yy.X, PR.yy.X, MR.yy.X, MD.yy.X, OZ.yy.X, XP.yy.X),sum) %>% ungroup

PERSdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT.yy.F,
  data = all_pers,
  nest = TRUE)
