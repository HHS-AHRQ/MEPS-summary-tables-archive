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

# Adults advised to quit smoking
  if(year == 2002)
    FYC <- FYC %>% rename(ADNSMK42 = ADDSMK42)

  FYC <- FYC %>%
    mutate(
      adult_nosmok = recode_factor(ADNSMK42, .default = "Missing", .missing = "Missing", 
        "1" = "Told to quit",
        "2" = "Not told to quit",
        "3" = "Had no visits in the last 12 months",
        "-9" = "Not ascertained",
        "-1" = "Inapplicable"))
# Employment Status
  if(year == 1996)
    FYC <- FYC %>% mutate(EMPST53 = EMPST96, EMPST42 = EMPST2, EMPST31 = EMPST1)

  FYC <- FYC %>%
    mutate_at(vars(EMPST53, EMPST42, EMPST31), funs(replace(., .< 0, NA))) %>%
    mutate(employ_last = coalesce(EMPST53, EMPST42, EMPST31))

  FYC <- FYC %>% mutate(
    employed = 1*(employ_last==1) + 2*(employ_last > 1),
    employed = replace(employed, is.na(employed) & AGELAST < 16, 9),
    employed = recode_factor(employed, .default = "Missing", .missing = "Missing", 
      "1" = "Employed",
      "2" = "Not employed",
      "9" = "Inapplicable (age < 16)"))

SAQdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~SAQWT.yy.F,
  data = FYC,
  nest = TRUE)

results <- svyby(~adult_nosmok, FUN = svytotal, by = ~employed, design = subset(SAQdsgn, ADSMOK42==1))
print(results)
