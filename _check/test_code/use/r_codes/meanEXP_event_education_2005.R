# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h97.ssp');
  year <- 2005

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU05, VARSTR=VARSTR05)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT05F = WTDPER05)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE05X, AGE42X, AGE31X))

  FYC$ind = 1  

# Education
  if(year <= 1998){
    FYC <- FYC %>% mutate(EDUCYR = EDUCYR05)
  }else if(year <= 2004){
    FYC <- FYC %>% mutate(EDUCYR = EDUCYEAR)
  }

  if(year >= 2012){
    FYC <- FYC %>%
      mutate(
        less_than_hs = (0 <= EDRECODE & EDRECODE < 13),
        high_school  = (EDRECODE == 13),
        some_college = (EDRECODE > 13))

  }else{
    FYC <- FYC %>%
      mutate(
        less_than_hs = (0 <= EDUCYR & EDUCYR < 12),
        high_school  = (EDUCYR == 12),
        some_college = (EDUCYR > 12))
  }

  FYC <- FYC %>% mutate(
    education = 1*less_than_hs + 2*high_school + 3*some_college,
    education = replace(education, AGELAST < 18, 9),
    education = recode_factor(education, .default = "Missing",
      "1" = "Less than high school",
      "2" = "High school",
      "3" = "Some college",
      "9" = "Inapplicable (age < 18)",
      "0" = "Missing"))

# Add aggregate event variables
  FYC <- FYC %>% mutate(
    HHTEXP05 = HHAEXP05 + HHNEXP05, # Home Health Agency + Independent providers
    ERTEXP05 = ERFEXP05 + ERDEXP05, # Doctor + Facility Expenses for OP, ER, IP events
    IPTEXP05 = IPFEXP05 + IPDEXP05,
    OPTEXP05 = OPFEXP05 + OPDEXP05, # All Outpatient
    OPYEXP05 = OPVEXP05 + OPSEXP05, # Physician only
    OPZEXP05 = OPOEXP05 + OPPEXP05, # Non-physician only
    OMAEXP05 = VISEXP05 + OTHEXP05) # Other medical equipment and services

  FYC <- FYC %>% mutate(
    TOTUSE05 = ((DVTOT05 > 0) + (RXTOT05 > 0) + (OBTOTV05 > 0) +
                  (OPTOTV05 > 0) + (ERTOT05 > 0) + (IPDIS05 > 0) +
                  (HHTOTD05 > 0) + (OMAEXP05 > 0))
  )

FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT05F,
  data = FYC,
  nest = TRUE)

# Loop over event types
  events <- c("TOT", "DVT", "RX",  "OBV", "OBD", "OBO",
              "OPT", "OPY", "OPZ", "ERT", "IPT", "HHT", "OMA")

  results <- list()
  for(ev in events) {
    key <- paste0(ev, "EXP", "05")
    formula <- as.formula(sprintf("~%s", key))
    results[[key]] <- svyby(formula, FUN = svymean, by = ~education, design = subset(FYCdsgn, FYC[[key]] > 0))
  }
  print(results)
