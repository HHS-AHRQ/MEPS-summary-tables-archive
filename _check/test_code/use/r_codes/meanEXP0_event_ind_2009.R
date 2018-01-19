# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h129.ssp');
  year <- 2009

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU09, VARSTR=VARSTR09)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT09F = WTDPER09)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE09X, AGE42X, AGE31X))

  FYC$ind = 1  

# Add aggregate event variables
  FYC <- FYC %>% mutate(
    HHTEXP09 = HHAEXP09 + HHNEXP09, # Home Health Agency + Independent providers
    ERTEXP09 = ERFEXP09 + ERDEXP09, # Doctor + Facility Expenses for OP, ER, IP events
    IPTEXP09 = IPFEXP09 + IPDEXP09,
    OPTEXP09 = OPFEXP09 + OPDEXP09, # All Outpatient
    OPYEXP09 = OPVEXP09 + OPSEXP09, # Physician only
    OPZEXP09 = OPOEXP09 + OPPEXP09, # Non-physician only
    OMAEXP09 = VISEXP09 + OTHEXP09) # Other medical equipment and services

  FYC <- FYC %>% mutate(
    TOTUSE09 = ((DVTOT09 > 0) + (RXTOT09 > 0) + (OBTOTV09 > 0) +
                  (OPTOTV09 > 0) + (ERTOT09 > 0) + (IPDIS09 > 0) +
                  (HHTOTD09 > 0) + (OMAEXP09 > 0))
  )

FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT09F,
  data = FYC,
  nest = TRUE)


# Loop over event types
  events <- c("TOT", "DVT", "RX",  "OBV", "OBD", "OBO",
              "OPT", "OPY", "OPZ", "ERT", "IPT", "HHT", "OMA")

  results <- list()
  for(ev in events) {
    key <- paste0(ev, "EXP")
    formula <- as.formula(sprintf("~%s09", key))
    results[[key]] <- svyby(formula, FUN = svymean, by = ~ind, design = FYCdsgn)
  }
  print(results)
