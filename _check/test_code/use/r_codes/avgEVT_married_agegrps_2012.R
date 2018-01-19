# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h155.ssp');
  year <- 2012

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU12, VARSTR=VARSTR12)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT12F = WTDPER12)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE12X, AGE42X, AGE31X))

  FYC$ind = 1  

# Age groups
# To compute for all age groups, replace 'agegrps' in the 'svyby' function with 'agegrps_v2X' or 'agegrps_v3X'
  FYC <- FYC %>%
    mutate(agegrps = cut(AGELAST,
      breaks = c(-1, 4.5, 17.5, 44.5, 64.5, Inf),
      labels = c("Under 5","5-17","18-44","45-64","65+"))) %>%
    mutate(agegrps_v2X = cut(AGELAST,
      breaks = c(-1, 17.5 ,64.5, Inf),
      labels = c("Under 18","18-64","65+"))) %>%
    mutate(agegrps_v3X = cut(AGELAST,
      breaks = c(-1, 4.5, 6.5, 12.5, 17.5, 18.5, 24.5, 29.5, 34.5, 44.5, 54.5, 64.5, Inf),
      labels = c("Under 5", "5-6", "7-12", "13-17", "18", "19-24", "25-29",
                 "30-34", "35-44", "45-54", "55-64", "65+")))

# Marital status
  if(year == 1996){
    FYC <- FYC %>%
      mutate(MARRY42X = ifelse(MARRY2X <= 6, MARRY2X, MARRY2X-6),
             MARRY31X = ifelse(MARRY1X <= 6, MARRY1X, MARRY1X-6))
  }

  FYC <- FYC %>%
    mutate_at(vars(starts_with("MARRY")), funs(replace(., .< 0, NA))) %>%
    mutate(married = coalesce(MARRY12X, MARRY42X, MARRY31X)) %>%
    mutate(married = recode_factor(married, .default = "Missing",
      "1" = "Married",
      "2" = "Widowed",
      "3" = "Divorced",
      "4" = "Separated",
      "5" = "Never married",
      "6" = "Inapplicable (age < 16)"))

# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(married,agegrps,ind, DUPERSID, PERWT12F, VARSTR, VARPSU)

# Load event files
  RX <- read.xport('C:/MEPS/h152a.ssp')
  DVT <- read.xport('C:/MEPS/h152b.ssp')
  IPT <- read.xport('C:/MEPS/h152d.ssp')
  ERT <- read.xport('C:/MEPS/h152e.ssp')
  OPT <- read.xport('C:/MEPS/h152f.ssp')
  OBV <- read.xport('C:/MEPS/h152g.ssp')
  HHT <- read.xport('C:/MEPS/h152h.ssp')

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
           PR12X = PV12X + TR12X,
           OZ12X = OF12X + SL12X + OT12X + OR12X + OU12X + WC12X + VA12X) %>%
    select(DUPERSID, event, event_v2X, SEEDOC,
      XP12X, SF12X, MR12X, MD12X, PR12X, OZ12X)

pers_events <- stacked_events %>%
  group_by(DUPERSID) %>%
  summarise(ANY = sum(XP12X >= 0),
            EXP = sum(XP12X > 0),
            SLF = sum(SF12X > 0),
            MCR = sum(MR12X > 0),
            MCD = sum(MD12X > 0),
            PTR = sum(PR12X > 0),
            OTZ = sum(OZ12X > 0)) %>%
  ungroup

n_events <- full_join(pers_events,FYCsub,by='DUPERSID') %>%
  mutate_at(vars(ANY,EXP,SLF,MCR,MCD,PTR,OTZ),
            function(x) ifelse(is.na(x),0,x))

nEVTdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT12F,
  data = n_events,
  nest = TRUE)

svyby(~ANY, FUN=svymean, by = ~married + agegrps, design = nEVTdsgn)
