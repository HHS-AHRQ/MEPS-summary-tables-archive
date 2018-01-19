# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h181.ssp');
  year <- 2015
  
  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE15X, AGE42X, AGE31X))

  FYC$ind = 1

# Diabetes care: Eye exam
  FYC <- FYC %>%
    mutate(past_year = (DSEY1553==1 | DSEY1653==1),
           more_year = (DSEY1453==1 | DSEB1453==1),
           never_chk = (DSEYNV53 == 1),
           non_resp = (DSEY1553 %in% c(-7,-8,-9))
    )

  FYC <- FYC %>%
    mutate(
      diab_eye = as.factor(case_when(
        .$past_year ~ "In the past year",
        .$more_year ~ "More than 1 year ago",
        .$never_chk ~ "Never had eye exam",
        .$non_resp ~ "Don\'t know/Non-response",
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

DIABdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~DIABW15F,
  data = FYC,
  nest = TRUE)

svyby(~diab_eye, FUN = svymean, by = ~health, design = DIABdsgn)
