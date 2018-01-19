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

# Poverty status
  if(year == 1996)
    FYC <- FYC %>% rename(POVCAT96 = POVCAT)

  FYC <- FYC %>%
    mutate(poverty = recode_factor(POVCAT05, .default = "Missing",
      "1" = "Negative or poor",
      "2" = "Near-poor",
      "3" = "Low income",
      "4" = "Middle income",
      "5" = "High income"))

# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(ind,poverty, DUPERSID, PERWT05F, VARSTR, VARPSU)

# Load event files
  RX <- read.xport('C:/MEPS/h94a.ssp')
  DVT <- read.xport('C:/MEPS/h94b.ssp')
  IPT <- read.xport('C:/MEPS/h94d.ssp')
  ERT <- read.xport('C:/MEPS/h94e.ssp')
  OPT <- read.xport('C:/MEPS/h94f.ssp')
  OBV <- read.xport('C:/MEPS/h94g.ssp')
  HHT <- read.xport('C:/MEPS/h94h.ssp')

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
           PR05X = PV05X + TR05X,
           OZ05X = OF05X + SL05X + OT05X + OR05X + OU05X + WC05X + VA05X) %>%
    select(DUPERSID, event, event_v2X, SEEDOC,
      XP05X, SF05X, MR05X, MD05X, PR05X, OZ05X)

  EVENTS <- stacked_events %>% full_join(FYCsub, by='DUPERSID')

EVNTdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT05F,           
  data = EVENTS,
  nest = TRUE)

svyby(~(XP05X >= 0), FUN=svytotal, by = ~ind + poverty, design = subset(EVNTdsgn, XP05X >= 0))
