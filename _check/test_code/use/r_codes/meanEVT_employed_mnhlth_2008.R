# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h121.ssp');
  year <- 2008

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU08, VARSTR=VARSTR08)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT08F = WTDPER08)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE08X, AGE42X, AGE31X))

  FYC$ind = 1  

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

# Employment Status
  if(year == 1996)
    FYC <- FYC %>% mutate(EMPST53 = EMPST96, EMPST42 = EMPST2, EMPST31 = EMPST1)

  FYC <- FYC %>%
    mutate_at(vars(EMPST53, EMPST42, EMPST31), funs(replace(., .< 0, NA))) %>%
    mutate(employ_last = coalesce(EMPST53, EMPST42, EMPST31))

  FYC <- FYC %>% mutate(
    employed = 1*(employ_last==1) + 2*(employ_last > 1),
    employed = replace(employed, is.na(employed) & AGELAST < 16, 9),
    employed = recode_factor(employed, .default = "Missing",
      "1" = "Employed",
      "2" = "Not employed",
      "9" = "Inapplicable (age < 16)"))

# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(employed,mnhlth,ind, DUPERSID, PERWT08F, VARSTR, VARPSU)

# Load event files
  RX <- read.xport('C:/MEPS/h118a.ssp')
  DVT <- read.xport('C:/MEPS/h118b.ssp')
  IPT <- read.xport('C:/MEPS/h118d.ssp')
  ERT <- read.xport('C:/MEPS/h118e.ssp')
  OPT <- read.xport('C:/MEPS/h118f.ssp')
  OBV <- read.xport('C:/MEPS/h118g.ssp')
  HHT <- read.xport('C:/MEPS/h118h.ssp')

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
           PR08X = PV08X + TR08X,
           OZ08X = OF08X + SL08X + OT08X + OR08X + OU08X + WC08X + VA08X) %>%
    select(DUPERSID, event, event_v2X, SEEDOC,
      XP08X, SF08X, MR08X, MD08X, PR08X, OZ08X)

  EVENTS <- stacked_events %>% full_join(FYCsub, by='DUPERSID')

EVNTdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT08F,           
  data = EVENTS,
  nest = TRUE)

svyby(~XP08X, FUN=svymean, by = ~employed + mnhlth, design = subset(EVNTdsgn, XP08X >= 0))
