# Sum by person, condition, event;
all_persev <- all_events %>%
  group_by(ind, DUPERSID, VARSTR, VARPSU, PERWT.yy.F, Condition, event, count) %>%
  summarize_at(vars(SF.yy.X, PR.yy.X, MR.yy.X, MD.yy.X, OZ.yy.X, XP.yy.X),sum) %>% ungroup

PERSevnt <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT.yy.F,
  data = all_persev,
  nest = TRUE)
