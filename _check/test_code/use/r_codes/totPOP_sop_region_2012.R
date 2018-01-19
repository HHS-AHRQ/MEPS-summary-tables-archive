# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h155.ssp');
  year <- 2012

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU12, VARSTR=VARSTR12)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT12F = WTDPER12)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE12X, AGE42X, AGE31X))

  FYC$ind = 1  

# Census region
  if(year == 1996)
    FYC <- FYC %>% mutate(REGION42 = REGION2, REGION31 = REGION1)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("REGION")), funs(replace(., .< 0, NA))) %>%
    mutate(region = coalesce(REGION12, REGION42, REGION31)) %>%
    mutate(region = recode_factor(region, .default = "Missing",
      "1" = "Northeast",
      "2" = "Midwest",
      "3" = "South",
      "4" = "West"))

# Add aggregate sources of payment
  if(year <= 1999)
    FYC <- FYC %>% mutate(TOTTRI12 = TOTCHM12)

  FYC <- FYC %>% mutate(
    TOTOTH12 = TOTOFD12 + TOTSTL12 + TOTOPR12 + TOTOPU12 + TOTOSR12,
    TOTOTZ12 = TOTOTH12 + TOTWCP12 + TOTVA12,
    TOTPTR12 = TOTPRV12 + TOTTRI12)

FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT12F,
  data = FYC,
  nest = TRUE)

# Loop over sources of payment
  sops <- c("EXP", "SLF", "PTR", "MCR", "MCD", "OTZ")
  results <- list()

  for(sp in sops) {
    key <- paste0("TOT", sp)
    formula <- as.formula(sprintf("~(%s12 > 0)", key))
    results[[key]] <- svyby(formula, FUN = svytotal, by = ~region, design = FYCdsgn)
  }

  print(results)
