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

RXdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT.yy.F,
  data = RX,
  nest = TRUE
)

results <- svyby(~count, by = ~TC1name, FUN = svytotal, design = RXdsgn)
print(results)
