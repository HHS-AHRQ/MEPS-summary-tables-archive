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

# Children receiving dental care
  FYC <- FYC %>%
    mutate(
      child_2to17 = (1 < AGELAST & AGELAST < 18),
      child_dental = ((DVTOT.yy. > 0) & (child_2to17==1))*1,
      child_dental = recode_factor(
        child_dental, .default = "Missing", .missing = "Missing", 
        "1" = "One or more dental visits",
        "0" = "No dental visits in past year"))

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

FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT.yy.F,
  data = FYC,
  nest = TRUE)

results <- svyby(~child_dental, FUN = svytotal, by = ~mnhlth, design = subset(FYCdsgn, child_2to17==1))
print(results)
