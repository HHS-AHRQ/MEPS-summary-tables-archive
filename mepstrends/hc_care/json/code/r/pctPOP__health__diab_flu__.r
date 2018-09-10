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

# Diabetes care: Flu shot
  if(year > 2007){
    FYC <- FYC %>%
      mutate(
        past_year = (DSFL.yy.53==1 | DSFL.ya.53==1),
        more_year = (DSFL.yb.53==1 | DSVB.yb.53==1),
        never_chk = (DSFLNV53 == 1),
        non_resp  = (DSFL.yy.53 %in% c(-7,-8,-9))
      )
  }else{
    FYC <- FYC %>%
      mutate(
        past_year = (FLUSHT53 == 1),
        more_year = (1 < FLUSHT53 & FLUSHT53 < 6),
        never_chk = (FLUSHT53 == 6),
        non_resp  = (FLUSHT53 %in% c(-7,-8,-9))
      )
  }

  FYC <- FYC %>%
    mutate(
      diab_flu = as.factor(case_when(
        .$past_year ~ "In the past year",
        .$more_year ~ "More than 1 year ago",
        .$never_chk ~ "Never had flu shot",
        .$non_resp ~ "Don\'t know/Non-response",
        TRUE ~ "Missing")))

# Perceived health status
  if(year == 1996)
    FYC <- FYC %>% mutate(RTHLTH53 = RTEHLTH2, RTHLTH42 = RTEHLTH2, RTHLTH31 = RTEHLTH1)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("RTHLTH")), funs(replace(., .< 0, NA))) %>%
    mutate(
      health = coalesce(RTHLTH53, RTHLTH42, RTHLTH31),
      health = recode_factor(health, .default = "Missing", .missing = "Missing", 
        "1" = "Excellent",
        "2" = "Very good",
        "3" = "Good",
        "4" = "Fair",
        "5" = "Poor"))

DIABdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~DIABW.yy.F,
  data = FYC,
  nest = TRUE)

results <- svyby(~diab_flu, FUN = svymean, by = ~health, design = DIABdsgn)
print(results)
