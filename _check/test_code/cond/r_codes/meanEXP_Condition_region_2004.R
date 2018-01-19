# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h89.ssp');
  year <- 2004

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU04, VARSTR=VARSTR04)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT04F = WTDPER04)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE04X, AGE42X, AGE31X))

  FYC$ind = 1  

# Census region
  if(year == 1996)
    FYC <- FYC %>% mutate(REGION42 = REGION2, REGION31 = REGION1)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("REGION")), funs(replace(., .< 0, NA))) %>%
    mutate(region = coalesce(REGION04, REGION42, REGION31)) %>%
    mutate(region = recode_factor(region, .default = "Missing",
      "1" = "Northeast",
      "2" = "Midwest",
      "3" = "South",
      "4" = "West"))

# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(region,ind, DUPERSID, PERWT04F, VARSTR, VARPSU)

# Load event files
  RX <- read.xport('C:/MEPS/h85a.ssp')
  DVT <- read.xport('C:/MEPS/h85b.ssp')
  IPT <- read.xport('C:/MEPS/h85d.ssp')
  ERT <- read.xport('C:/MEPS/h85e.ssp')
  OPT <- read.xport('C:/MEPS/h85f.ssp')
  OBV <- read.xport('C:/MEPS/h85g.ssp')
  HHT <- read.xport('C:/MEPS/h85h.ssp')

# Define sub-levels for office-based and outpatient
  OBV <- OBV %>%
    mutate(event_v2X = recode_factor(
      SEEDOC, .default = 'Missing', '1' = 'OBD', '2' = 'OBO'))

  OPT <- OPT %>%
    mutate(event_v2X = recode_factor(
      SEEDOC, .default = 'Missing', '1' = 'OPY', '2' = 'OPZ'))

# Sum RX purchases for each event
  RX <- RX %>%
    rename(EVNTIDX = LINKIDX) %>%
    group_by(DUPERSID,EVNTIDX) %>%
    summarise_at(vars(RXSF04X:RXXP04X),sum) %>%
    ungroup

# Stack events (dental visits and other medical not collected for events)
  stacked_events <- stack_events(RX, IPT, ERT, OPT, OBV, HHT, keep.vars = c('SEEDOC','event_v2X'))

  stacked_events <- stacked_events %>%
    mutate(event = data,
           PR04X = PV04X + TR04X,
           OZ04X = OF04X + SL04X + OT04X + OR04X + OU04X + WC04X + VA04X)

# Read in event-condition linking file
  clink1 = read.xport('C:/MEPS/h85if1.ssp') %>%
    select(DUPERSID,CONDIDX,EVNTIDX)

# Read in conditions file and merge with condition_codes, link file
  cond <- read.xport('C:/MEPS/h87.ssp') %>%
    select(DUPERSID, CONDIDX, CCCODEX) %>%
    mutate(CCS_Codes = as.numeric(as.character(CCCODEX))) %>%
    left_join(condition_codes, by = "CCS_Codes") %>%
    full_join(clink1, by = c("DUPERSID", "CONDIDX")) %>%
    distinct(DUPERSID, EVNTIDX, Condition, .keep_all=T)

# Merge events with conditions-link file and FYCsub
  all_events <- full_join(stacked_events, cond, by=c("DUPERSID","EVNTIDX")) %>%
    filter(!is.na(Condition),XP04X >= 0) %>%
    mutate(count = 1) %>%
    full_join(FYCsub, by = "DUPERSID")

# Sum by person, condition, across event
all_pers <- all_events %>%
  group_by(region,ind, DUPERSID, VARSTR, VARPSU, PERWT04F, Condition, count) %>%
  summarize_at(vars(SF04X, PR04X, MR04X, MD04X, OZ04X, XP04X),sum) %>% ungroup

PERSdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT04F,
  data = all_pers,
  nest = TRUE)

svyby(~XP04X, by = ~Condition + region, FUN = svymean, design = PERSdsgn)
