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

# Age groups
# To compute for all age groups, replace 'agegrps' in the 'svyby' function with 'agegrps_v2X' or 'agegrps_v3X'
  FYC <- FYC %>%
    mutate(agegrps = cut(AGELAST,
      breaks = c(-1, 4.5, 17.5, 44.5, 64.5, Inf),
      labels = c("Under 5","5-17","18-44","45-64","65+"))) %>%
    mutate(agegrps_v2X = cut(AGELAST,
      breaks = c(-1, 17.5 ,64.5, Inf),
      labels = c("Under 18","18-64","65+"))) %>%
    mutate(agegrps_v3X = cut(AGELAST,
      breaks = c(-1, 4.5, 6.5, 12.5, 17.5, 18.5, 24.5, 29.5, 34.5, 44.5, 54.5, 64.5, Inf),
      labels = c("Under 5", "5-6", "7-12", "13-17", "18", "19-24", "25-29",
                 "30-34", "35-44", "45-54", "55-64", "65+")))

DIABdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~DIABW.yy.F,
  data = FYC,
  nest = TRUE)

results <- svyby(~diab_foot, FUN = svymean, by = ~agegrps, design = DIABdsgn)
print(results)
