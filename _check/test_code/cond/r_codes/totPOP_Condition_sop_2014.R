# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h171.ssp');
  year <- 2014

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU14, VARSTR=VARSTR14)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT14F = WTDPER14)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE14X, AGE42X, AGE31X))

  FYC$ind = 1  

# Add aggregate sources of payment
  if(year <= 1999)
    FYC <- FYC %>% mutate(TOTTRI14 = TOTCHM14)

  FYC <- FYC %>% mutate(
    TOTOTH14 = TOTOFD14 + TOTSTL14 + TOTOPR14 + TOTOPU14 + TOTOSR14,
    TOTOTZ14 = TOTOTH14 + TOTWCP14 + TOTVA14,
    TOTPTR14 = TOTPRV14 + TOTTRI14)

# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(ind, DUPERSID, PERWT14F, VARSTR, VARPSU)

# Load event files
  RX <- read.xport('C:/MEPS/h168a.ssp')
  DVT <- read.xport('C:/MEPS/h168b.ssp')
  IPT <- read.xport('C:/MEPS/h168d.ssp')
  ERT <- read.xport('C:/MEPS/h168e.ssp')
  OPT <- read.xport('C:/MEPS/h168f.ssp')
  OBV <- read.xport('C:/MEPS/h168g.ssp')
  HHT <- read.xport('C:/MEPS/h168h.ssp')

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
    summarise_at(vars(RXSF14X:RXXP14X),sum) %>%
    ungroup

# Stack events (dental visits and other medical not collected for events)
  stacked_events <- stack_events(RX, IPT, ERT, OPT, OBV, HHT, keep.vars = c('SEEDOC','event_v2X'))

  stacked_events <- stacked_events %>%
    mutate(event = data,
           PR14X = PV14X + TR14X,
           OZ14X = OF14X + SL14X + OT14X + OR14X + OU14X + WC14X + VA14X)

# Read in event-condition linking file
  clink1 = read.xport('C:/MEPS/h168if1.ssp') %>%
    select(DUPERSID,CONDIDX,EVNTIDX)

# Read in conditions file and merge with condition_codes, link file
  cond <- read.xport('C:/MEPS/h170.ssp') %>%
    select(DUPERSID, CONDIDX, CCCODEX) %>%
    mutate(CCS_Codes = as.numeric(as.character(CCCODEX))) %>%
    left_join(condition_codes, by = "CCS_Codes") %>%
    full_join(clink1, by = c("DUPERSID", "CONDIDX")) %>%
    distinct(DUPERSID, EVNTIDX, Condition, .keep_all=T)

# Merge events with conditions-link file and FYCsub
  all_events <- full_join(stacked_events, cond, by=c("DUPERSID","EVNTIDX")) %>%
    filter(!is.na(Condition),XP14X >= 0) %>%
    mutate(count = 1) %>%
    full_join(FYCsub, by = "DUPERSID")

# Sum by person, condition, across event
all_pers <- all_events %>%
  group_by(ind, DUPERSID, VARSTR, VARPSU, PERWT14F, Condition, count) %>%
  summarize_at(vars(SF14X, PR14X, MR14X, MD14X, OZ14X, XP14X),sum) %>% ungroup

PERSdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT14F,
  data = all_pers,
  nest = TRUE)

svyby(~(XP14X > 0) + (SF14X > 0) + (MR14X > 0) + (MD14X > 0) + (PR14X > 0) + (OZ14X > 0),
 by = ~Condition, FUN = svytotal, design = PERSdsgn)
