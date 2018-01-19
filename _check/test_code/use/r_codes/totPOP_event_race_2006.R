# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h105.ssp');
  year <- 2006

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU06, VARSTR=VARSTR06)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT06F = WTDPER06)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE06X, AGE42X, AGE31X))

  FYC$ind = 1  

# Race / ethnicity
  # Starting in 2012, RACETHX replaced RACEX;
  if(year >= 2012){
    FYC <- FYC %>%
      mutate(white_oth=F,
        hisp   = (RACETHX == 1),
        white  = (RACETHX == 2),
        black  = (RACETHX == 3),
        native = (RACETHX > 3 & RACEV1X %in% c(3,6)),
        asian  = (RACETHX > 3 & RACEV1X %in% c(4,5)))

  }else if(year >= 2002){
    FYC <- FYC %>%
      mutate(white_oth=0,
        hisp   = (RACETHNX == 1),
        white  = (RACETHNX == 4 & RACEX == 1),
        black  = (RACETHNX == 2),
        native = (RACETHNX >= 3 & RACEX %in% c(3,6)),
        asian  = (RACETHNX >= 3 & RACEX %in% c(4,5)))

  }else{
    FYC <- FYC %>%
      mutate(
        hisp = (RACETHNX == 1),
        black = (RACETHNX == 2),
        white_oth = (RACETHNX == 3),
        white = 0,native=0,asian=0)
  }

  FYC <- FYC %>% mutate(
    race = 1*hisp + 2*white + 3*black + 4*native + 5*asian + 9*white_oth,
    race = recode_factor(race, .default = "Missing",
      "1" = "Hispanic",
      "2" = "White",
      "3" = "Black",
      "4" = "Amer. Indian, AK Native, or mult. races",
      "5" = "Asian, Hawaiian, or Pacific Islander",
      "9" = "White and other"))

# Add aggregate event variables
  FYC <- FYC %>% mutate(
    HHTEXP06 = HHAEXP06 + HHNEXP06, # Home Health Agency + Independent providers
    ERTEXP06 = ERFEXP06 + ERDEXP06, # Doctor + Facility Expenses for OP, ER, IP events
    IPTEXP06 = IPFEXP06 + IPDEXP06,
    OPTEXP06 = OPFEXP06 + OPDEXP06, # All Outpatient
    OPYEXP06 = OPVEXP06 + OPSEXP06, # Physician only
    OPZEXP06 = OPOEXP06 + OPPEXP06, # Non-physician only
    OMAEXP06 = VISEXP06 + OTHEXP06) # Other medical equipment and services

  FYC <- FYC %>% mutate(
    TOTUSE06 = ((DVTOT06 > 0) + (RXTOT06 > 0) + (OBTOTV06 > 0) +
                  (OPTOTV06 > 0) + (ERTOT06 > 0) + (IPDIS06 > 0) +
                  (HHTOTD06 > 0) + (OMAEXP06 > 0))
  )

FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT06F,
  data = FYC,
  nest = TRUE)

# Loop over event types
  events <- c("TOTUSE", "DVTOT", "RXTOT", "OBTOTV", "OBDRV", "OBOTHV",
              "OPTOTV", "OPDRV", "OPOTHV", "ERTOT", "IPDIS", "HHTOTD", "OMAEXP")

  results <- list()
  for(ev in events) {
    key <- ev
    formula <- as.formula(sprintf("~(%s06 > 0)", key))
    results[[key]] <- svyby(formula, FUN = svytotal, by = ~race, design = FYCdsgn)
  }
  print(results)
