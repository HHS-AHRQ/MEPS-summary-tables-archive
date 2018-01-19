n_pers <- all_pers %>%
  gather(sop,XP,SF.yy.X, PR.yy.X, MR.yy.X, MD.yy.X, OZ.yy.X, XP.yy.X) %>%
  mutate(sop = substr(sop,1,2))

ndsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT.yy.F,
  data = n_pers,
  nest = TRUE)
