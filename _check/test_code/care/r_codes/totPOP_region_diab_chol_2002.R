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

# Diabetes care: Lipid profile
  if(year > 2007){
    FYC <- FYC %>%
      mutate(
        past_year = (DSCH0253==1 | DSCH0353==1),
        more_year = (DSCH0153==1 | DSCB0153==1),
        never_chk = (DSCHNV53 == 1),
        non_resp  = (DSCH0253 %in% c(-7,-8,-9))
      )
  }else{
    FYC <- FYC %>%
      mutate(
        past_year = (CHOLCK53 == 1),
        more_year = (1 < CHOLCK53 & CHOLCK53 < 6),
        never_chk = (CHOLCK53 == 6),
        non_resp  = (CHOLCK53 %in% c(-7,-8,-9))
      )
  }

  FYC <- FYC %>%
    mutate(
      diab_chol = as.factor(case_when(
        .$past_year ~ "In the past year",
        .$more_year ~ "More than 1 year ago",
        .$never_chk ~ "Never had cholesterol checked",
        .$non_resp ~ "Don\'t know/Non-response",
        TRUE ~ "Missing")))

# Census region
  if(year == 1996)
    FYC <- FYC %>% mutate(REGION42 = REGION2, REGION31 = REGION1)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("REGION")), funs(replace(., .< 0, NA))) %>%
    mutate(region = coalesce(REGION02, REGION42, REGION31)) %>%
    mutate(region = recode_factor(region, .default = "Missing",
      "1" = "Northeast",
      "2" = "Midwest",
      "3" = "South",
      "4" = "West"))

DIABdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~DIABW02F,
  data = FYC,
  nest = TRUE)

svyby(~diab_chol, FUN = svytotal, by = ~region, design = DIABdsgn)
