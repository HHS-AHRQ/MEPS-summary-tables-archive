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

# Reason for difficulty receiving needed care
  FYC <- FYC %>%
    mutate(
      delay_MD  = (MDUNAB42 == 1 | MDDLAY42==1)*1,
      delay_DN  = (DNUNAB42 == 1 | DNDLAY42==1)*1,
      delay_PM  = (PMUNAB42 == 1 | PMDLAY42==1)*1,

      afford_MD = (MDDLRS42 == 1 | MDUNRS42 == 1)*1,
      afford_DN = (DNDLRS42 == 1 | DNUNRS42 == 1)*1,
      afford_PM = (PMDLRS42 == 1 | PMUNRS42 == 1)*1,

      insure_MD = (MDDLRS42 %in% c(2,3) | MDUNRS42 %in% c(2,3))*1,
      insure_DN = (DNDLRS42 %in% c(2,3) | DNUNRS42 %in% c(2,3))*1,
      insure_PM = (PMDLRS42 %in% c(2,3) | PMUNRS42 %in% c(2,3))*1,

      other_MD  = (MDDLRS42 > 3 | MDUNRS42 > 3)*1,
      other_DN  = (DNDLRS42 > 3 | DNUNRS42 > 3)*1,
      other_PM  = (PMDLRS42 > 3 | PMUNRS42 > 3)*1,

      delay_ANY  = (delay_MD  | delay_DN  | delay_PM)*1,
      afford_ANY = (afford_MD | afford_DN | afford_PM)*1,
      insure_ANY = (insure_MD | insure_DN | insure_PM)*1,
      other_ANY  = (other_MD  | other_DN  | other_PM)*1)

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

FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT.yy.F,
  data = FYC,
  nest = TRUE)

results <- svyby(~afford_ANY + insure_ANY + other_ANY, FUN = svymean, by = ~health, design = subset(FYCdsgn, ACCELI42==1 & delay_ANY==1))
print(results)
