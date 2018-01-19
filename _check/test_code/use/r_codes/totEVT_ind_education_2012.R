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

# Education
  if(year <= 1998){
    FYC <- FYC %>% mutate(EDUCYR = EDUCYR12)
  }else if(year <= 2004){
    FYC <- FYC %>% mutate(EDUCYR = EDUCYEAR)
  }

  if(year >= 2012){
    FYC <- FYC %>%
      mutate(
        less_than_hs = (0 <= EDRECODE & EDRECODE < 13),
        high_school  = (EDRECODE == 13),
        some_college = (EDRECODE > 13))

  }else{
    FYC <- FYC %>%
      mutate(
        less_than_hs = (0 <= EDUCYR & EDUCYR < 12),
        high_school  = (EDUCYR == 12),
        some_college = (EDUCYR > 12))
  }

  FYC <- FYC %>% mutate(
    education = 1*less_than_hs + 2*high_school + 3*some_college,
    education = replace(education, AGELAST < 18, 9),
    education = recode_factor(education, .default = "Missing",
      "1" = "Less than high school",
      "2" = "High school",
      "3" = "Some college",
      "9" = "Inapplicable (age < 18)",
      "0" = "Missing"))

# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(ind,education, DUPERSID, PERWT12F, VARSTR, VARPSU)

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

  EVENTS <- stacked_events %>% full_join(FYCsub, by='DUPERSID')

EVNTdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT12F,           
  data = EVENTS,
  nest = TRUE)

svyby(~(XP12X >= 0), FUN=svytotal, by = ~ind + education, design = subset(EVNTdsgn, XP12X >= 0))
