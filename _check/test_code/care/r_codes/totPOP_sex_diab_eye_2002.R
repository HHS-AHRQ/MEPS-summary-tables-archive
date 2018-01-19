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

# Diabetes care: Eye exam
  FYC <- FYC %>%
    mutate(past_year = (DSEY0253==1 | DSEY0353==1),
           more_year = (DSEY0153==1 | DSEB0153==1),
           never_chk = (DSEYNV53 == 1),
           non_resp = (DSEY0253 %in% c(-7,-8,-9))
    )

  FYC <- FYC %>%
    mutate(
      diab_eye = as.factor(case_when(
        .$past_year ~ "In the past year",
        .$more_year ~ "More than 1 year ago",
        .$never_chk ~ "Never had eye exam",
        .$non_resp ~ "Don\'t know/Non-response",
        TRUE ~ "Missing")))

# Sex
  FYC <- FYC %>%
    mutate(sex = recode_factor(SEX, .default = "Missing",
      "1" = "Male",
      "2" = "Female"))

DIABdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~DIABW02F,
  data = FYC,
  nest = TRUE)

svyby(~diab_eye, FUN = svytotal, by = ~sex, design = DIABdsgn)
