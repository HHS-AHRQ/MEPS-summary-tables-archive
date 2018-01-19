# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h28.ssp');
  year <- 1998

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU98, VARSTR=VARSTR98)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT98F = WTDPER98)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE98X, AGE42X, AGE31X))

  FYC$ind = 1  

# Perceived health status
  if(year == 1996)
    FYC <- FYC %>% mutate(RTHLTH53 = RTEHLTH2, RTHLTH42 = RTEHLTH2, RTHLTH31 = RTEHLTH1)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("RTHLTH")), funs(replace(., .< 0, NA))) %>%
    mutate(
      health = coalesce(RTHLTH53, RTHLTH42, RTHLTH31),
      health = recode_factor(health, .default = "Missing",
        "1" = "Excellent",
        "2" = "Very good",
        "3" = "Good",
        "4" = "Fair",
        "5" = "Poor"))

# Add aggregate event variables
  FYC <- FYC %>% mutate(
    HHTEXP98 = HHAEXP98 + HHNEXP98, # Home Health Agency + Independent providers
    ERTEXP98 = ERFEXP98 + ERDEXP98, # Doctor + Facility Expenses for OP, ER, IP events
    IPTEXP98 = IPFEXP98 + IPDEXP98,
    OPTEXP98 = OPFEXP98 + OPDEXP98, # All Outpatient
    OPYEXP98 = OPVEXP98 + OPSEXP98, # Physician only
    OPZEXP98 = OPOEXP98 + OPPEXP98, # Non-physician only
    OMAEXP98 = VISEXP98 + OTHEXP98) # Other medical equipment and services

  FYC <- FYC %>% mutate(
    TOTUSE98 = ((DVTOT98 > 0) + (RXTOT98 > 0) + (OBTOTV98 > 0) +
                  (OPTOTV98 > 0) + (ERTOT98 > 0) + (IPDIS98 > 0) +
                  (HHTOTD98 > 0) + (OMAEXP98 > 0))
  )

FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT98F,
  data = FYC,
  nest = TRUE)

# Loop over event types
  events <- c("TOT", "DVT", "RX",  "OBV", "OBD", "OBO",
              "OPT", "OPY", "OPZ", "ERT", "IPT", "HHT", "OMA")

  results <- list()
  for(ev in events) {
    key <- paste0(ev, "EXP")
    formula <- as.formula(sprintf("~(%s98 > 0)", key))
    results[[key]] <- svyby(formula, FUN = svymean, by = ~health, design = FYCdsgn)
  }
  print(results)
