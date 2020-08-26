# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

year <- .year.

# Load RX file
  RX <- read_sas("C:/MEPS/.RX..sas7bdat")
  
  if(year <= 2001) RX <- RX %>% mutate(VARPSU = VARPSU.yy., VARSTR = VARSTR.yy.)
  if(year <= 1998) RX <- RX %>% rename(PERWT.yy.F = WTDPER.yy.)

# For 1996-2013, merge with RX Multum Lexicon Addendum files
  if(year <= 2013) {
    Multum <- read_sas("C:/MEPS/.Multum..sas7bdat")
    RX <- RX %>%
      select(-starts_with("TC"), -one_of("PREGCAT", "RXDRGNAM")) %>%
      left_join(Multum, by = c("DUPERSID", "RXRECIDX"))
  }
  
# Merge with therapeutic class names ('tc1_names')
  RX <- RX %>%
    left_join(tc1_names, by = "TC1") %>%
    mutate(count = 1)

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

results <- svyby(~count, by = ~RXDRGNAM, FUN = svytotal, design = DRGdsgn)
print(results)
