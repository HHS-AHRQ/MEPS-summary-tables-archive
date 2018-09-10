# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/.FYC..ssp');
  year <- .year.

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU.yy., VARSTR=VARSTR.yy.)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT.yy.F = WTDPER.yy.)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE.yy.X, AGE42X, AGE31X))

  FYC$ind = 1  

# Perceived mental health
  if(year == 1996)
    FYC <- FYC %>% mutate(MNHLTH53 = MNTHLTH2, MNHLTH42 = MNTHLTH2, MNHLTH31 = MNTHLTH1)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("MNHLTH")), funs(replace(., .< 0, NA))) %>%
    mutate(mnhlth = coalesce(MNHLTH53, MNHLTH42, MNHLTH31)) %>%
    mutate(mnhlth = recode_factor(mnhlth, .default = "Missing", .missing = "Missing", 
      "1" = "Excellent",
      "2" = "Very good",
      "3" = "Good",
      "4" = "Fair",
      "5" = "Poor"))

# Employment Status
  if(year == 1996)
    FYC <- FYC %>% mutate(EMPST53 = EMPST96, EMPST42 = EMPST2, EMPST31 = EMPST1)

  FYC <- FYC %>%
    mutate_at(vars(EMPST53, EMPST42, EMPST31), funs(replace(., .< 0, NA))) %>%
    mutate(employ_last = coalesce(EMPST53, EMPST42, EMPST31))

  FYC <- FYC %>% mutate(
    employed = 1*(employ_last==1) + 2*(employ_last > 1),
    employed = replace(employed, is.na(employed) & AGELAST < 16, 9),
    employed = recode_factor(employed, .default = "Missing", .missing = "Missing", 
      "1" = "Employed",
      "2" = "Not employed",
      "9" = "Inapplicable (age < 16)"))

FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT.yy.F,
  data = FYC,
  nest = TRUE)

results <- svyby(~TOTEXP.yy., FUN=svymean, by = ~employed + mnhlth, design = FYCdsgn)
print(results)
