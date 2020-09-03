
DRGpers <- RX %>%
  filter(!RXNDC %in% c("-9","-15") & !RXDRGNAM %in% c("-9","-15")) %>%
  group_by(DUPERSID, VARSTR, VARPSU, PERWTF, RXDRGNAM) %>%
  summarise(n_RX = sum(count), RXXPX = sum(RXXPX)) %>%
  mutate(count = 1) %>%
  ungroup

DRGdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWTF,
  data = DRGpers,
  nest = TRUE
)


TC1pers <- RX %>%
  group_by(DUPERSID, VARSTR, VARPSU, PERWTF, TC1name) %>%
  summarise(n_RX = sum(count), RXXPX = sum(RXXPX)) %>%
  mutate(count = 1) %>%
  ungroup

TC1dsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWTF,
  data = TC1pers,
  nest = TRUE
)


RXdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWTF,
  data = RX,
  nest = TRUE
)
