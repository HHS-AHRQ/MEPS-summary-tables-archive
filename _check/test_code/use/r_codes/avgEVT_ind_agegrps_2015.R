# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h181.ssp');
  year <- 2015

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU15, VARSTR=VARSTR15)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT15F = WTDPER15)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE15X, AGE42X, AGE31X))

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

# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(ind,agegrps, DUPERSID, PERWT15F, VARSTR, VARPSU)

# Load event files
  RX <- read.xport('C:/MEPS/h178a.ssp')
  DVT <- read.xport('C:/MEPS/h178b.ssp')
  IPT <- read.xport('C:/MEPS/h178d.ssp')
  ERT <- read.xport('C:/MEPS/h178e.ssp')
  OPT <- read.xport('C:/MEPS/h178f.ssp')
  OBV <- read.xport('C:/MEPS/h178g.ssp')
  HHT <- read.xport('C:/MEPS/h178h.ssp')

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
           PR15X = PV15X + TR15X,
           OZ15X = OF15X + SL15X + OT15X + OR15X + OU15X + WC15X + VA15X) %>%
    select(DUPERSID, event, event_v2X, SEEDOC,
      XP15X, SF15X, MR15X, MD15X, PR15X, OZ15X)

pers_events <- stacked_events %>%
  group_by(DUPERSID) %>%
  summarise(ANY = sum(XP15X >= 0),
            EXP = sum(XP15X > 0),
            SLF = sum(SF15X > 0),
            MCR = sum(MR15X > 0),
            MCD = sum(MD15X > 0),
            PTR = sum(PR15X > 0),
            OTZ = sum(OZ15X > 0)) %>%
  ungroup

n_events <- full_join(pers_events,FYCsub,by='DUPERSID') %>%
  mutate_at(vars(ANY,EXP,SLF,MCR,MCD,PTR,OTZ),
            function(x) ifelse(is.na(x),0,x))

nEVTdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT15F,
  data = n_events,
  nest = TRUE)

svyby(~ANY, FUN=svymean, by = ~ind + agegrps, design = nEVTdsgn)
