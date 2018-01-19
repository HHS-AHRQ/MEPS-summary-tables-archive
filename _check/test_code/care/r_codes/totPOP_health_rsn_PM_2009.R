# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h129.ssp');
  year <- 2009
  
  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE09X, AGE42X, AGE31X))

  FYC$ind = 1

# Reason for difficulty receiving needed prescribed medicines
  FYC <- FYC %>%
    mutate(delay_PM  = (PMUNAB42 == 1 | PMDLAY42 == 1)*1,
           afford_PM = (PMDLRS42 == 1 | PMUNRS42 == 1)*1,
           insure_PM = (PMDLRS42 %in% c(2,3) | PMUNRS42 %in% c(2,3))*1,
           other_PM  = (PMDLRS42 > 3 | PMUNRS42 > 3)*1)

# Perceived health status
  if(year == 1996)
    FYC <- FYC %>% mutate(RTHLTH53 = RTEHLTH2, RTHLTH42 = RTEHLTH2, RTHLTH31 = RTEHLTH1)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("RTHLTH")), funs(replace(., .< 0, NA))) %>%
    mutate(
      health = coalesce(RTHLTH53, RTHLTH42, RTHLTH31),
      health = recode_factor(health, .default = "Missing",
        "1" = "Excellent",
        "2" = "Very good",
        "3" = "Good",
        "4" = "Fair",
        "5" = "Poor"))

FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT09F,
  data = FYC,
  nest = TRUE)

svyby(~afford_PM + insure_PM + other_PM, FUN = svytotal, by = ~health, design = subset(FYCdsgn, ACCELI42==1 & delay_PM==1))
