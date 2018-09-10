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

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU.yy., VARSTR=VARSTR.yy.)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT.yy.F = WTDPER.yy.)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE.yy.X, AGE42X, AGE31X))

  FYC$ind = 1  

# Marital status
  if(year == 1996){
    FYC <- FYC %>%
      mutate(MARRY42X = ifelse(MARRY2X <= 6, MARRY2X, MARRY2X-6),
             MARRY31X = ifelse(MARRY1X <= 6, MARRY1X, MARRY1X-6))
  }

  FYC <- FYC %>%
    mutate_at(vars(starts_with("MARRY")), funs(replace(., .< 0, NA))) %>%
    mutate(married = coalesce(MARRY.yy.X, MARRY42X, MARRY31X)) %>%
    mutate(married = recode_factor(married, .default = "Missing", .missing = "Missing", 
      "1" = "Married",
      "2" = "Widowed",
      "3" = "Divorced",
      "4" = "Separated",
      "5" = "Never married",
      "6" = "Inapplicable (age < 16)"))

# Sex
  FYC <- FYC %>%
    mutate(sex = recode_factor(SEX, .default = "Missing", .missing = "Missing", 
      "1" = "Male",
      "2" = "Female"))

FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT.yy.F,
  data = FYC,
  nest = TRUE)

results <- svyby(~(PERWT.yy.F > 0), FUN = svytotal, by = ~sex + married, design = FYCdsgn)
print(results)
