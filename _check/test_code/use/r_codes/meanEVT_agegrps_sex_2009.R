# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h129.ssp');
  year <- 2009

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU09, VARSTR=VARSTR09)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT09F = WTDPER09)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE09X, AGE42X, AGE31X))

  FYC$ind = 1  

# Sex
  FYC <- FYC %>%
    mutate(sex = recode_factor(SEX, .default = "Missing",
      "1" = "Male",
      "2" = "Female"))

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
  FYCsub <- FYC %>% select(agegrps,sex,ind, DUPERSID, PERWT09F, VARSTR, VARPSU)

# Load event files
  RX <- read.xport('C:/MEPS/h126a.ssp')
  DVT <- read.xport('C:/MEPS/h126b.ssp')
  IPT <- read.xport('C:/MEPS/h126d.ssp')
  ERT <- read.xport('C:/MEPS/h126e.ssp')
  OPT <- read.xport('C:/MEPS/h126f.ssp')
  OBV <- read.xport('C:/MEPS/h126g.ssp')
  HHT <- read.xport('C:/MEPS/h126h.ssp')

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
           PR09X = PV09X + TR09X,
           OZ09X = OF09X + SL09X + OT09X + OR09X + OU09X + WC09X + VA09X) %>%
    select(DUPERSID, event, event_v2X, SEEDOC,
      XP09X, SF09X, MR09X, MD09X, PR09X, OZ09X)

  EVENTS <- stacked_events %>% full_join(FYCsub, by='DUPERSID')

EVNTdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT09F,           
  data = EVENTS,
  nest = TRUE)

svyby(~XP09X, FUN=svymean, by = ~agegrps + sex, design = subset(EVNTdsgn, XP09X >= 0))
