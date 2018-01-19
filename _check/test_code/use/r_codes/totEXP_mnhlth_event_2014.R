# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h171.ssp');
  year <- 2014

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU14, VARSTR=VARSTR14)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT14F = WTDPER14)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE14X, AGE42X, AGE31X))

  FYC$ind = 1  

# Add aggregate event variables
  FYC <- FYC %>% mutate(
    HHTEXP14 = HHAEXP14 + HHNEXP14, # Home Health Agency + Independent providers
    ERTEXP14 = ERFEXP14 + ERDEXP14, # Doctor + Facility Expenses for OP, ER, IP events
    IPTEXP14 = IPFEXP14 + IPDEXP14,
    OPTEXP14 = OPFEXP14 + OPDEXP14, # All Outpatient
    OPYEXP14 = OPVEXP14 + OPSEXP14, # Physician only
    OPZEXP14 = OPOEXP14 + OPPEXP14, # Non-physician only
    OMAEXP14 = VISEXP14 + OTHEXP14) # Other medical equipment and services

  FYC <- FYC %>% mutate(
    TOTUSE14 = ((DVTOT14 > 0) + (RXTOT14 > 0) + (OBTOTV14 > 0) +
                  (OPTOTV14 > 0) + (ERTOT14 > 0) + (IPDIS14 > 0) +
                  (HHTOTD14 > 0) + (OMAEXP14 > 0))
  )

# Perceived mental health
  if(year == 1996)
    FYC <- FYC %>% mutate(MNHLTH53 = MNTHLTH2, MNHLTH42 = MNTHLTH2, MNHLTH31 = MNTHLTH1)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("MNHLTH")), funs(replace(., .< 0, NA))) %>%
    mutate(mnhlth = coalesce(MNHLTH53, MNHLTH42, MNHLTH31)) %>%
    mutate(mnhlth = recode_factor(mnhlth, .default = "Missing",
      "1" = "Excellent",
      "2" = "Very good",
      "3" = "Good",
      "4" = "Fair",
      "5" = "Poor"))

FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT14F,
  data = FYC,
  nest = TRUE)

# Loop over event types
  events <- c("TOT", "DVT", "RX",  "OBV", "OBD", "OBO",
              "OPT", "OPY", "OPZ", "ERT", "IPT", "HHT", "OMA")

  results <- list()
  for(ev in events) {
    key <- paste0(ev, "EXP")
    formula <- as.formula(sprintf("~%s14", key))
    results[[key]] <- svyby(formula, FUN = svytotal, by = ~mnhlth, design = FYCdsgn)
  }
  print(results)
