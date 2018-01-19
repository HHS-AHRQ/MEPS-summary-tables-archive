# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h38.ssp');
  year <- 1999

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU99, VARSTR=VARSTR99)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT99F = WTDPER99)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE99X, AGE42X, AGE31X))

  FYC$ind = 1  

# Poverty status
  if(year == 1996)
    FYC <- FYC %>% rename(POVCAT96 = POVCAT)

  FYC <- FYC %>%
    mutate(poverty = recode_factor(POVCAT99, .default = "Missing",
      "1" = "Negative or poor",
      "2" = "Near-poor",
      "3" = "Low income",
      "4" = "Middle income",
      "5" = "High income"))

# Add aggregate sources of payment
  if(year <= 1999)
    FYC <- FYC %>% mutate(TOTTRI99 = TOTCHM99)

  FYC <- FYC %>% mutate(
    TOTOTH99 = TOTOFD99 + TOTSTL99 + TOTOPR99 + TOTOPU99 + TOTOSR99,
    TOTOTZ99 = TOTOTH99 + TOTWCP99 + TOTVA99,
    TOTPTR99 = TOTPRV99 + TOTTRI99)

FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT99F,
  data = FYC,
  nest = TRUE)

# Loop over sources of payment
  sops <- c("EXP", "SLF", "PTR", "MCR", "MCD", "OTZ")
  results <- list()

  for(sp in sops) {
    key <- paste0("TOT", sp)
    formula <- as.formula(sprintf("~%s99", key))
    results[[key]] <- svyby(formula, FUN = svymean, by = ~poverty, design = FYCdsgn)
  }

  print(results)
