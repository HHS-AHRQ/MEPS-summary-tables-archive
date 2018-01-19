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

# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(ind, DUPERSID, PERWT98F, VARSTR, VARPSU)

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

# Sum RX purchases for each event
  RX <- RX %>%
    rename(EVNTIDX = LINKIDX) %>%
    group_by(DUPERSID,EVNTIDX) %>%
    summarise_at(vars(RXSF98X:RXXP98X),sum) %>%
    ungroup

# Stack events (dental visits and other medical not collected for events)
  stacked_events <- stack_events(RX, IPT, ERT, OPT, OBV, HHT, keep.vars = c('SEEDOC','event_v2X'))

  stacked_events <- stacked_events %>%
    mutate(event = data,
           PR98X = PV98X + TR98X,
           OZ98X = OF98X + SL98X + OT98X + OR98X + OU98X + WC98X + VA98X)

# Read in event-condition linking file
  clink1 = read.xport('C:/MEPS/h26if1.ssp') %>%
    select(DUPERSID,CONDIDX,EVNTIDX)

# Read in conditions file and merge with condition_codes, link file
  cond <- read.xport('C:/MEPS/h27.ssp') %>%
    select(DUPERSID, CONDIDX, CCCODEX) %>%
    mutate(CCS_Codes = as.numeric(as.character(CCCODEX))) %>%
    left_join(condition_codes, by = "CCS_Codes") %>%
    full_join(clink1, by = c("DUPERSID", "CONDIDX")) %>%
    distinct(DUPERSID, EVNTIDX, Condition, .keep_all=T)

# Merge events with conditions-link file and FYCsub
  all_events <- full_join(stacked_events, cond, by=c("DUPERSID","EVNTIDX")) %>%
    filter(!is.na(Condition),XP98X >= 0) %>%
    mutate(count = 1) %>%
    full_join(FYCsub, by = "DUPERSID")

EVNTdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT98F,           
  data = all_events,
  nest = TRUE) 

svyby(~count, by = ~Condition + event,FUN = svytotal, design = EVNTdsgn)
