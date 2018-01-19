# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h97.ssp');
  year <- 2005
  
  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE05X, AGE42X, AGE31X))

  FYC$ind = 1

# Rating for care (adults)
  FYC <- FYC %>%
    mutate(
      adult_rating = as.factor(case_when(
        .$ADHECR42 >= 9 ~ "9-10 rating",
        .$ADHECR42 >= 7 ~ "7-8 rating",
        .$ADHECR42 >= 0 ~ "0-6 rating",
        .$ADHECR42 == -1 ~ "Inapplicable",
        .$ADHECR42 <= -7 ~ "Don\'t know/Non-response",
        TRUE ~ "Missing")))

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

SAQdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~SAQWT05F,
  data = FYC,
  nest = TRUE)

svyby(~adult_rating, FUN=svytotal, by = ~health, design = subset(SAQdsgn, ADAPPT42 >= 1 & AGELAST >= 18))
