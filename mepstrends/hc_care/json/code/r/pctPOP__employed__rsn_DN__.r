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
  
  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE.yy.X, AGE42X, AGE31X))

  FYC$ind = 1

# Reason for difficulty receiving needed dental care
  FYC <- FYC %>%
    mutate(delay_DN  = (DNUNAB42 == 1 | DNDLAY42 == 1)*1,
           afford_DN = (DNDLRS42 == 1 | DNUNRS42 == 1)*1,
           insure_DN = (DNDLRS42 %in% c(2,3) | DNUNRS42 %in% c(2,3))*1,
           other_DN  = (DNDLRS42 > 3 | DNUNRS42 > 3)*1)

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

results <- svyby(~afford_DN + insure_DN + other_DN, FUN = svymean, by = ~employed, design = subset(FYCdsgn, ACCELI42==1 & delay_DN==1))
print(results)
