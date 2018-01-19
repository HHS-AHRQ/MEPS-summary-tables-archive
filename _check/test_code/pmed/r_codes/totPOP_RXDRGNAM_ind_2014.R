# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load RX file and merge with therapeutic class names ('tc1_names')
  RX <- read.xport("C:/MEPS/h168a.ssp") %>%
    left_join(tc1_names, by = "TC1") %>%
    mutate(count = 1)

DRGpers <- RX %>%
  filter(RXNDC != "-9" & RXDRGNAM != "-9") %>%
  group_by(DUPERSID, VARSTR, VARPSU, PERWT14F, RXDRGNAM) %>%
  summarise(n_RX = sum(count), RXXP14X = sum(RXXP14X)) %>%
  mutate(count = 1) %>%
  ungroup

DRGdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT14F,
  data = DRGpers,
  nest = TRUE
)

svyby(~count, by = ~RXDRGNAM, FUN = svytotal, design = DRGdsgn)
