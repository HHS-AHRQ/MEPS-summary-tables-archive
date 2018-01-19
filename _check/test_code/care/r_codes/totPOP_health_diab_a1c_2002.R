# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h70.ssp');
  year <- 2002
  
  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE02X, AGE42X, AGE31X))

  FYC$ind = 1

# Diabetes care: Hemoglobin A1c measurement
  FYC <- FYC %>%
    mutate(diab_a1c = ifelse(0 < DSA1C53 & DSA1C53 < 96, 1, DSA1C53)) %>%
    mutate(diab_a1c = replace(diab_a1c,DSA1C53==96,0)) %>%
    mutate(diab_a1c = recode_factor(diab_a1c, .default = "Missing",
      "1" = "Had measurement",
      "0" = "Did not have measurement",
      "-7" = "Don\'t know/Non-response",
      "-8" = "Don\'t know/Non-response",
      "-9" = "Don\'t know/Non-response",
      "-1" = "Inapplicable"))

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

DIABdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~DIABW02F,
  data = FYC,
  nest = TRUE)

svyby(~diab_a1c, FUN = svytotal, by = ~health, design = DIABdsgn)
