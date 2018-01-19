# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h79.ssp');
  year <- 2003

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU03, VARSTR=VARSTR03)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT03F = WTDPER03)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE03X, AGE42X, AGE31X))

  FYC$ind = 1  

# Sex
  FYC <- FYC %>%
    mutate(sex = recode_factor(SEX, .default = "Missing",
      "1" = "Male",
      "2" = "Female"))

# Poverty status
  if(year == 1996)
    FYC <- FYC %>% rename(POVCAT96 = POVCAT)

  FYC <- FYC %>%
    mutate(poverty = recode_factor(POVCAT03, .default = "Missing",
      "1" = "Negative or poor",
      "2" = "Near-poor",
      "3" = "Low income",
      "4" = "Middle income",
      "5" = "High income"))

# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(poverty,sex,ind, DUPERSID, PERWT03F, VARSTR, VARPSU)

# Load event files
  RX <- read.xport('C:/MEPS/h77a.ssp')
  DVT <- read.xport('C:/MEPS/h77b.ssp')
  IPT <- read.xport('C:/MEPS/h77d.ssp')
  ERT <- read.xport('C:/MEPS/h77e.ssp')
  OPT <- read.xport('C:/MEPS/h77f.ssp')
  OBV <- read.xport('C:/MEPS/h77g.ssp')
  HHT <- read.xport('C:/MEPS/h77h.ssp')

# Define sub-levels for office-based and outpatient
  OBV <- OBV %>%
    mutate(event_v2X = recode_factor(
      SEEDOC, .default = 'Missing', '1' = 'OBD', '2' = 'OBO'))

  OPT <- OPT %>%
    mutate(event_v2X = recode_factor(
      SEEDOC, .default = 'Missing', '1' = 'OPY', '2' = 'OPZ'))

# Stack events
  stacked_events <- stack_events(RX, DVT, IPT, ERT, OPT, OBV, HHT,
    keep.vars = c('SEEDOC','event_v2X'))

  stacked_events <- stacked_events %>%
    mutate(event = data,
           PR03X = PV03X + TR03X,
           OZ03X = OF03X + SL03X + OT03X + OR03X + OU03X + WC03X + VA03X) %>%
    select(DUPERSID, event, event_v2X, SEEDOC,
      XP03X, SF03X, MR03X, MD03X, PR03X, OZ03X)

  EVENTS <- stacked_events %>% full_join(FYCsub, by='DUPERSID')

EVNTdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT03F,           
  data = EVENTS,
  nest = TRUE)

svyby(~XP03X, FUN=svymean, by = ~poverty + sex, design = subset(EVNTdsgn, XP03X >= 0))
