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
  FYCsub <- FYC %>% select(ind,employed, DUPERSID, PERWT98F, VARSTR, VARPSU)

# Load event files
  RX <- read.xport('C:/MEPS/h26a.ssp')
  DVT <- read.xport('C:/MEPS/hc26bf1.ssp')
  IPT <- read.xport('C:/MEPS/h26df1.ssp')
  ERT <- read.xport('C:/MEPS/h26ef1.ssp')
  OPT <- read.xport('C:/MEPS/h26ff1.ssp')
  OBV <- read.xport('C:/MEPS/h26gf1.ssp')
  HHT <- read.xport('C:/MEPS/h26hf1.ssp')

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
           PR98X = PV98X + TR98X,
           OZ98X = OF98X + SL98X + OT98X + OR98X + OU98X + WC98X + VA98X) %>%
    select(DUPERSID, event, event_v2X, SEEDOC,
      XP98X, SF98X, MR98X, MD98X, PR98X, OZ98X)

  EVENTS <- stacked_events %>% full_join(FYCsub, by='DUPERSID')

EVNTdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT98F,           
  data = EVENTS,
  nest = TRUE)

svyby(~(XP98X >= 0), FUN=svytotal, by = ~ind + employed, design = subset(EVNTdsgn, XP98X >= 0))
