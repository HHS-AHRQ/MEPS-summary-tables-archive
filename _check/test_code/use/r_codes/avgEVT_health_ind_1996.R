# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h12.ssp');
  year <- 1996

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU96, VARSTR=VARSTR96)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT96F = WTDPER96)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE96X, AGE42X, AGE31X))

  FYC$ind = 1  

# Perceived health status
  if(year == 1996)
    FYC <- FYC %>% mutate(RTHLTH53 = RTEHLTH2, RTHLTH42 = RTEHLTH2, RTHLTH31 = RTEHLTH1)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("RTHLTH")), funs(replace(., .< 0, NA))) %>%
    mutate(
      health = coalesce(RTHLTH53, RTHLTH42, RTHLTH31),
      health = recode_factor(health, .default = "Missing",
        "1" = "Excellent",
        "2" = "Very good",
        "3" = "Good",
        "4" = "Fair",
        "5" = "Poor"))

# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(health,ind, DUPERSID, PERWT96F, VARSTR, VARPSU)

# Load event files
  RX <- read.xport('C:/MEPS/hc10a.ssp')
  DVT <- read.xport('C:/MEPS/hc10bf1.ssp')
  IPT <- read.xport('C:/MEPS/hc10df1.ssp')
  ERT <- read.xport('C:/MEPS/hc10ef1.ssp')
  OPT <- read.xport('C:/MEPS/hc10ff1.ssp')
  OBV <- read.xport('C:/MEPS/hc10gf1.ssp')
  HHT <- read.xport('C:/MEPS/hc10hf1.ssp')

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
           PR96X = PV96X + TR96X,
           OZ96X = OF96X + SL96X + OT96X + OR96X + OU96X + WC96X + VA96X) %>%
    select(DUPERSID, event, event_v2X, SEEDOC,
      XP96X, SF96X, MR96X, MD96X, PR96X, OZ96X)

pers_events <- stacked_events %>%
  group_by(DUPERSID) %>%
  summarise(ANY = sum(XP96X >= 0),
            EXP = sum(XP96X > 0),
            SLF = sum(SF96X > 0),
            MCR = sum(MR96X > 0),
            MCD = sum(MD96X > 0),
            PTR = sum(PR96X > 0),
            OTZ = sum(OZ96X > 0)) %>%
  ungroup

n_events <- full_join(pers_events,FYCsub,by='DUPERSID') %>%
  mutate_at(vars(ANY,EXP,SLF,MCR,MCD,PTR,OTZ),
            function(x) ifelse(is.na(x),0,x))

nEVTdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT96F,
  data = n_events,
  nest = TRUE)

svyby(~ANY, FUN=svymean, by = ~health + ind, design = nEVTdsgn)
