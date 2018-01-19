# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h105.ssp');
  year <- 2006
  
  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE06X, AGE42X, AGE31X))

  FYC$ind = 1

# Diabetes care: Foot care
  if(year > 2007){
    FYC <- FYC %>%
      mutate(
        past_year = (DSFT0653==1 | DSFT0753==1),
        more_year = (DSFT0553==1 | DSFB0553==1),
        never_chk = (DSFTNV53 == 1),
        non_resp  = (DSFT0653 %in% c(-7,-8,-9)),
        inapp     = (DSFT0653 == -1),
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

# Poverty status
  if(year == 1996)
    FYC <- FYC %>% rename(POVCAT96 = POVCAT)

  FYC <- FYC %>%
    mutate(poverty = recode_factor(POVCAT06, .default = "Missing",
      "1" = "Negative or poor",
      "2" = "Near-poor",
      "3" = "Low income",
      "4" = "Middle income",
      "5" = "High income"))

DIABdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~DIABW06F,
  data = FYC,
  nest = TRUE)

svyby(~diab_foot, FUN = svymean, by = ~poverty, design = DIABdsgn)
