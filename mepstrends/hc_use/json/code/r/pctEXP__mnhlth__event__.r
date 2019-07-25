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

# Add aggregate event variables
  FYC <- FYC %>% mutate(
    HHTEXP.yy. = HHAEXP.yy. + HHNEXP.yy., # Home Health Agency + Independent providers
    ERTEXP.yy. = ERFEXP.yy. + ERDEXP.yy., # Doctor + Facility Expenses for OP, ER, IP events
    IPTEXP.yy. = IPFEXP.yy. + IPDEXP.yy.,
    OPTEXP.yy. = OPFEXP.yy. + OPDEXP.yy., # All Outpatient
    OPYEXP.yy. = OPVEXP.yy. + OPSEXP.yy., # Outpatient - Physician only
    OMAEXP.yy. = VISEXP.yy. + OTHEXP.yy.) # Other medical equipment and services

  FYC <- FYC %>% mutate(
    TOTUSE.yy. = ((DVTOT.yy. > 0) + (RXTOT.yy. > 0) + (OBTOTV.yy. > 0) +
                  (OPTOTV.yy. > 0) + (ERTOT.yy. > 0) + (IPDIS.yy. > 0) +
                  (HHTOTD.yy. > 0) + (OMAEXP.yy. > 0))
  )

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

# Loop over event types
  events <- c("TOT", "DVT", "RX",  "OBV", "OBD",
              "OPT", "OPY", "ERT", "IPT", "HHT", "OMA")

  results <- list()
  for(ev in events) {
    key <- paste0(ev, "EXP")
    formula <- as.formula(sprintf("~(%s.yy. > 0)", key))
    results[[key]] <- svyby(formula, FUN = svymean, by = ~mnhlth, design = FYCdsgn)
  }

print(results)
