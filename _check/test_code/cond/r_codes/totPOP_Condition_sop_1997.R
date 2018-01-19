# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h20.ssp');
  year <- 1997

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU97, VARSTR=VARSTR97)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT97F = WTDPER97)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE97X, AGE42X, AGE31X))

  FYC$ind = 1  

# Add aggregate sources of payment
  if(year <= 1999)
    FYC <- FYC %>% mutate(TOTTRI97 = TOTCHM97)

  FYC <- FYC %>% mutate(
    TOTOTH97 = TOTOFD97 + TOTSTL97 + TOTOPR97 + TOTOPU97 + TOTOSR97,
    TOTOTZ97 = TOTOTH97 + TOTWCP97 + TOTVA97,
    TOTPTR97 = TOTPRV97 + TOTTRI97)

# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(ind, DUPERSID, PERWT97F, VARSTR, VARPSU)

# Load event files
  RX <- read.xport('C:/MEPS/h16a.ssp')
  DVT <- read.xport('C:/MEPS/hc16bf1.ssp')
  IPT <- read.xport('C:/MEPS/hc16df1.ssp')
  ERT <- read.xport('C:/MEPS/hc16ef1.ssp')
  OPT <- read.xport('C:/MEPS/hc16ff1.ssp')
  OBV <- read.xport('C:/MEPS/hc16gf1.ssp')
  HHT <- read.xport('C:/MEPS/hc16hf1.ssp')

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
    summarise_at(vars(RXSF97X:RXXP97X),sum) %>%
    ungroup

# Stack events (dental visits and other medical not collected for events)
  stacked_events <- stack_events(RX, IPT, ERT, OPT, OBV, HHT, keep.vars = c('SEEDOC','event_v2X'))

  stacked_events <- stacked_events %>%
    mutate(event = data,
           PR97X = PV97X + TR97X,
           OZ97X = OF97X + SL97X + OT97X + OR97X + OU97X + WC97X + VA97X)

# Read in event-condition linking file
  clink1 = read.xport('C:/MEPS/h16if1.ssp') %>%
    select(DUPERSID,CONDIDX,EVNTIDX)

# Read in conditions file and merge with condition_codes, link file
  cond <- read.xport('C:/MEPS/h18.ssp') %>%
    select(DUPERSID, CONDIDX, CCCODEX) %>%
    mutate(CCS_Codes = as.numeric(as.character(CCCODEX))) %>%
    left_join(condition_codes, by = "CCS_Codes") %>%
    full_join(clink1, by = c("DUPERSID", "CONDIDX")) %>%
    distinct(DUPERSID, EVNTIDX, Condition, .keep_all=T)

# Merge events with conditions-link file and FYCsub
  all_events <- full_join(stacked_events, cond, by=c("DUPERSID","EVNTIDX")) %>%
    filter(!is.na(Condition),XP97X >= 0) %>%
    mutate(count = 1) %>%
    full_join(FYCsub, by = "DUPERSID")

# Sum by person, condition, across event
all_pers <- all_events %>%
  group_by(ind, DUPERSID, VARSTR, VARPSU, PERWT97F, Condition, count) %>%
  summarize_at(vars(SF97X, PR97X, MR97X, MD97X, OZ97X, XP97X),sum) %>% ungroup

PERSdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT97F,
  data = all_pers,
  nest = TRUE)

svyby(~(XP97X > 0) + (SF97X > 0) + (MR97X > 0) + (MD97X > 0) + (PR97X > 0) + (OZ97X > 0),
 by = ~Condition, FUN = svytotal, design = PERSdsgn)
