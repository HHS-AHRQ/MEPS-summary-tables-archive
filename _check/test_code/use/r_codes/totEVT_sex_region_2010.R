# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h138.ssp');
  year <- 2010

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU10, VARSTR=VARSTR10)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT10F = WTDPER10)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE10X, AGE42X, AGE31X))

  FYC$ind = 1  

# Census region
  if(year == 1996)
    FYC <- FYC %>% mutate(REGION42 = REGION2, REGION31 = REGION1)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("REGION")), funs(replace(., .< 0, NA))) %>%
    mutate(region = coalesce(REGION10, REGION42, REGION31)) %>%
    mutate(region = recode_factor(region, .default = "Missing",
      "1" = "Northeast",
      "2" = "Midwest",
      "3" = "South",
      "4" = "West"))

# Sex
  FYC <- FYC %>%
    mutate(sex = recode_factor(SEX, .default = "Missing",
      "1" = "Male",
      "2" = "Female"))

# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(sex,region,ind, DUPERSID, PERWT10F, VARSTR, VARPSU)

# Load event files
  RX <- read.xport('C:/MEPS/h135a.ssp')
  DVT <- read.xport('C:/MEPS/h135b.ssp')
  IPT <- read.xport('C:/MEPS/h135d.ssp')
  ERT <- read.xport('C:/MEPS/h135e.ssp')
  OPT <- read.xport('C:/MEPS/h135f.ssp')
  OBV <- read.xport('C:/MEPS/h135g.ssp')
  HHT <- read.xport('C:/MEPS/h135h.ssp')

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
           PR10X = PV10X + TR10X,
           OZ10X = OF10X + SL10X + OT10X + OR10X + OU10X + WC10X + VA10X) %>%
    select(DUPERSID, event, event_v2X, SEEDOC,
      XP10X, SF10X, MR10X, MD10X, PR10X, OZ10X)

  EVENTS <- stacked_events %>% full_join(FYCsub, by='DUPERSID')

EVNTdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT10F,           
  data = EVENTS,
  nest = TRUE)

svyby(~(XP10X >= 0), FUN=svytotal, by = ~sex + region, design = subset(EVNTdsgn, XP10X >= 0))
