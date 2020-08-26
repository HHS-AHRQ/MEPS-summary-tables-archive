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

# Education
  if(year <= 1998){
    FYC <- FYC %>% mutate(EDUCYR = EDUCYR.yy.)
  }else if(year <= 2004){
    FYC <- FYC %>% mutate(EDUCYR = EDUCYEAR)
  }

  if(year >= 2012 & year < 2016){
    FYC <- FYC %>%
      mutate(
        less_than_hs = (0 <= EDRECODE & EDRECODE < 13),
        high_school  = (EDRECODE == 13),
        some_college = (EDRECODE > 13))

  }else{
    FYC <- FYC %>%
      mutate(
        less_than_hs = (0 <= EDUCYR & EDUCYR < 12),
        high_school  = (EDUCYR == 12),
        some_college = (EDUCYR > 12))
  }

  FYC <- FYC %>% mutate(
    education = 1*less_than_hs + 2*high_school + 3*some_college,
    education = replace(education, AGELAST < 18, 9),
    education = recode_factor(education, .default = "Missing", .missing = "Missing",
      "1" = "Less than high school",
      "2" = "High school",
      "3" = "Some college",
      "9" = "Inapplicable (age < 18)",
      "0" = "Missing"))

DIABdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~DIABW.yy.F,
  data = FYC,
  nest = TRUE)

results <- svyby(~diab_foot, FUN = svymean, by = ~education, design = DIABdsgn)
print(results)
