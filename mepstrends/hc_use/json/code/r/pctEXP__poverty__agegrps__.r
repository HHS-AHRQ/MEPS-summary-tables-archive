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

FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT.yy.F,
  data = FYC,
  nest = TRUE)

results <- svyby(~(TOTEXP.yy. > 0), FUN = svymean, by = ~poverty + agegrps, design = FYCdsgn)
print(results)
