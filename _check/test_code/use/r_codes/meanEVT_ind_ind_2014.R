# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h171.ssp');
  year <- 2014

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU14, VARSTR=VARSTR14)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT14F = WTDPER14)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE14X, AGE42X, AGE31X))

  FYC$ind = 1  

# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(ind, DUPERSID, PERWT14F, VARSTR, VARPSU)

# Load event files
  RX <- read.xport('C:/MEPS/h168a.ssp')
  DVT <- read.xport('C:/MEPS/h168b.ssp')
  IPT <- read.xport('C:/MEPS/h168d.ssp')
  ERT <- read.xport('C:/MEPS/h168e.ssp')
  OPT <- read.xport('C:/MEPS/h168f.ssp')
  OBV <- read.xport('C:/MEPS/h168g.ssp')
  HHT <- read.xport('C:/MEPS/h168h.ssp')

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
           PR14X = PV14X + TR14X,
           OZ14X = OF14X + SL14X + OT14X + OR14X + OU14X + WC14X + VA14X) %>%
    select(DUPERSID, event, event_v2X, SEEDOC,
      XP14X, SF14X, MR14X, MD14X, PR14X, OZ14X)

  EVENTS <- stacked_events %>% full_join(FYCsub, by='DUPERSID')

EVNTdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT14F,           
  data = EVENTS,
  nest = TRUE)

svyby(~XP14X, FUN=svymean, by = ~ind, design = subset(EVNTdsgn, XP14X >= 0))
