# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read_sas('C:/MEPS/.FYC..sas7bdat');
  year <- .year.
  
  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE.yy.X, AGE42X, AGE31X))

  FYC$ind = 1

# Diabetes care: Foot care
  if(year > 2007){
    FYC <- FYC %>%
      mutate(
        past_year = (DSFT.yy.53==1 | DSFT.ya.53==1),
        more_year = (DSFT.yb.53==1 | DSFB.yb.53==1),
        never_chk = (DSFTNV53 == 1),
        non_resp  = (DSFT.yy.53 %in% c(-7,-8,-9)),
        inapp     = (DSFT.yy.53 == -1),
        not_past_year = FALSE
      )
  }else{
    FYC <- FYC %>%
      mutate(
        past_year = (DSCKFT53 >= 1),
        not_past_year = (DSCKFT53 == 0),
        non_resp  = (DSCKFT53 %in% c(-7,-8,-9)),
        inapp     = (DSCKFT53 == -1),
        more_year = FALSE,
        never_chk = FALSE
      )
  }

  FYC <- FYC %>%
    mutate(
      diab_foot = as.factor(case_when(
        .$past_year ~ "In the past year",
        .$more_year ~ "More than 1 year ago",
        .$never_chk ~ "Never had feet checked",
        .$not_past_year ~ "No exam in past year",
        .$non_resp ~ "Don\'t know/Non-response",
        .$inapp ~ "Inapplicable",
        TRUE ~ "Missing")))

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

DIABdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~DIABW.yy.F,
  data = FYC,
  nest = TRUE)

results <- svyby(~diab_foot, FUN = svytotal, by = ~mnhlth, design = DIABdsgn)
print(results)
