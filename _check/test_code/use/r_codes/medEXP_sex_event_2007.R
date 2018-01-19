# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h113.ssp');
  year <- 2007

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU07, VARSTR=VARSTR07)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT07F = WTDPER07)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE07X, AGE42X, AGE31X))

  FYC$ind = 1  

# Add aggregate event variables
  FYC <- FYC %>% mutate(
    HHTEXP07 = HHAEXP07 + HHNEXP07, # Home Health Agency + Independent providers
    ERTEXP07 = ERFEXP07 + ERDEXP07, # Doctor + Facility Expenses for OP, ER, IP events
    IPTEXP07 = IPFEXP07 + IPDEXP07,
    OPTEXP07 = OPFEXP07 + OPDEXP07, # All Outpatient
    OPYEXP07 = OPVEXP07 + OPSEXP07, # Physician only
    OPZEXP07 = OPOEXP07 + OPPEXP07, # Non-physician only
    OMAEXP07 = VISEXP07 + OTHEXP07) # Other medical equipment and services

  FYC <- FYC %>% mutate(
    TOTUSE07 = ((DVTOT07 > 0) + (RXTOT07 > 0) + (OBTOTV07 > 0) +
                  (OPTOTV07 > 0) + (ERTOT07 > 0) + (IPDIS07 > 0) +
                  (HHTOTD07 > 0) + (OMAEXP07 > 0))
  )

# Sex
  FYC <- FYC %>%
    mutate(sex = recode_factor(SEX, .default = "Missing",
      "1" = "Male",
      "2" = "Female"))

FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT07F,
  data = FYC,
  nest = TRUE)

# Loop over event types
  events <- c("TOT", "DVT", "RX",  "OBV", "OBD", "OBO",
              "OPT", "OPY", "OPZ", "ERT", "IPT", "HHT", "OMA")

  results <- list()
  for(ev in events) {
    key <- paste0(ev, "EXP", "07")
    formula <- as.formula(sprintf("~%s", key))
    results[[key]] <- svyby(formula, FUN = svyquantile, by = ~sex, design = subset(FYCdsgn, FYC[[key]] > 0), quantiles=c(0.5), ci=T, method="constant")
  }
  print(results)
