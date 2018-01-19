# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h38.ssp');
  year <- 1999

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU99, VARSTR=VARSTR99)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT99F = WTDPER99)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE99X, AGE42X, AGE31X))

  FYC$ind = 1  

# Census region
  if(year == 1996)
    FYC <- FYC %>% mutate(REGION42 = REGION2, REGION31 = REGION1)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("REGION")), funs(replace(., .< 0, NA))) %>%
    mutate(region = coalesce(REGION99, REGION42, REGION31)) %>%
    mutate(region = recode_factor(region, .default = "Missing",
      "1" = "Northeast",
      "2" = "Midwest",
      "3" = "South",
      "4" = "West"))

# Education
  if(year <= 1998){
    FYC <- FYC %>% mutate(EDUCYR = EDUCYR99)
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
  FYCsub <- FYC %>% select(education,region,ind, DUPERSID, PERWT99F, VARSTR, VARPSU)

# Load event files
  RX <- read.xport('C:/MEPS/h33a.ssp')
  DVT <- read.xport('C:/MEPS/h33b.ssp')
  IPT <- read.xport('C:/MEPS/h33d.ssp')
  ERT <- read.xport('C:/MEPS/h33e.ssp')
  OPT <- read.xport('C:/MEPS/h33f.ssp')
  OBV <- read.xport('C:/MEPS/h33g.ssp')
  HHT <- read.xport('C:/MEPS/h33h.ssp')

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
           PR99X = PV99X + TR99X,
           OZ99X = OF99X + SL99X + OT99X + OR99X + OU99X + WC99X + VA99X) %>%
    select(DUPERSID, event, event_v2X, SEEDOC,
      XP99X, SF99X, MR99X, MD99X, PR99X, OZ99X)

  EVENTS <- stacked_events %>% full_join(FYCsub, by='DUPERSID')

EVNTdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT99F,           
  data = EVENTS,
  nest = TRUE)

svyby(~(XP99X >= 0), FUN=svytotal, by = ~education + region, design = subset(EVNTdsgn, XP99X >= 0))
