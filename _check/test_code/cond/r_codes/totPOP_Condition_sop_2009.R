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

# Add aggregate sources of payment
  if(year <= 1999)
    FYC <- FYC %>% mutate(TOTTRI09 = TOTCHM09)

  FYC <- FYC %>% mutate(
    TOTOTH09 = TOTOFD09 + TOTSTL09 + TOTOPR09 + TOTOPU09 + TOTOSR09,
    TOTOTZ09 = TOTOTH09 + TOTWCP09 + TOTVA09,
    TOTPTR09 = TOTPRV09 + TOTTRI09)

# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(ind, DUPERSID, PERWT09F, VARSTR, VARPSU)

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

# Sum RX purchases for each event
  RX <- RX %>%
    rename(EVNTIDX = LINKIDX) %>%
    group_by(DUPERSID,EVNTIDX) %>%
    summarise_at(vars(RXSF09X:RXXP09X),sum) %>%
    ungroup

# Stack events (dental visits and other medical not collected for events)
  stacked_events <- stack_events(RX, IPT, ERT, OPT, OBV, HHT, keep.vars = c('SEEDOC','event_v2X'))

  stacked_events <- stacked_events %>%
    mutate(event = data,
           PR09X = PV09X + TR09X,
           OZ09X = OF09X + SL09X + OT09X + OR09X + OU09X + WC09X + VA09X)

# Read in event-condition linking file
  clink1 = read.xport('C:/MEPS/h126if1.ssp') %>%
    select(DUPERSID,CONDIDX,EVNTIDX)

# Read in conditions file and merge with condition_codes, link file
  cond <- read.xport('C:/MEPS/h128.ssp') %>%
    select(DUPERSID, CONDIDX, CCCODEX) %>%
    mutate(CCS_Codes = as.numeric(as.character(CCCODEX))) %>%
    left_join(condition_codes, by = "CCS_Codes") %>%
    full_join(clink1, by = c("DUPERSID", "CONDIDX")) %>%
    distinct(DUPERSID, EVNTIDX, Condition, .keep_all=T)

# Merge events with conditions-link file and FYCsub
  all_events <- full_join(stacked_events, cond, by=c("DUPERSID","EVNTIDX")) %>%
    filter(!is.na(Condition),XP09X >= 0) %>%
    mutate(count = 1) %>%
    full_join(FYCsub, by = "DUPERSID")

# Sum by person, condition, across event
all_pers <- all_events %>%
  group_by(ind, DUPERSID, VARSTR, VARPSU, PERWT09F, Condition, count) %>%
  summarize_at(vars(SF09X, PR09X, MR09X, MD09X, OZ09X, XP09X),sum) %>% ungroup

PERSdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT09F,
  data = all_pers,
  nest = TRUE)

svyby(~(XP09X > 0) + (SF09X > 0) + (MR09X > 0) + (MD09X > 0) + (PR09X > 0) + (OZ09X > 0),
 by = ~Condition, FUN = svytotal, design = PERSdsgn)
