DRGpers <- RX %>%
  filter(RXNDC != "-9" & RXDRGNAM != "-9") %>%
  group_by(DUPERSID, VARSTR, VARPSU, PERWT.yy.F, RXDRGNAM) %>%
  summarise(n_RX = sum(count), RXXP.yy.X = sum(RXXP.yy.X)) %>%
  mutate(count = 1) %>%
  ungroup

DRGdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT.yy.F,
  data = DRGpers,
  nest = TRUE
)
