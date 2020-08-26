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

# Rating for care (adults)
  FYC <- FYC %>%
    mutate(
      adult_rating = as.factor(case_when(
        .$ADHECR42 >= 9 ~ "9-10 rating",
        .$ADHECR42 >= 7 ~ "7-8 rating",
        .$ADHECR42 >= 0 ~ "0-6 rating",
        .$ADHECR42 == -1 ~ "Inapplicable",
        .$ADHECR42 <= -7 ~ "Don\'t know/Non-response",
        TRUE ~ "Missing")))

# Poverty status
  if(year == 1996)
    FYC <- FYC %>% rename(POVCAT96 = POVCAT)

  FYC <- FYC %>%
    mutate(poverty = recode_factor(POVCAT.yy., .default = "Missing", .missing = "Missing", 
      "1" = "Negative or poor",
      "2" = "Near-poor",
      "3" = "Low income",
      "4" = "Middle income",
      "5" = "High income"))

SAQdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~SAQWT.yy.F,
  data = FYC,
  nest = TRUE)

results <- svyby(~adult_rating, FUN=svytotal, by = ~poverty, design = subset(SAQdsgn, ADAPPT42 >= 1 & AGELAST >= 18))
print(results)
