TC1pers <- RX %>%
  group_by(DUPERSID, VARSTR, VARPSU, PERWT.yy.F, TC1name) %>%
  summarise(n_RX = sum(count), RXXP.yy.X = sum(RXXP.yy.X)) %>%
  mutate(count = 1) %>%
  ungroup

TC1dsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT.yy.F,
  data = TC1pers,
  nest = TRUE
)
