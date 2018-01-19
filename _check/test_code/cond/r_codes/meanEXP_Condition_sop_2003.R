# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h79.ssp');
  year <- 2003

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU03, VARSTR=VARSTR03)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT03F = WTDPER03)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE03X, AGE42X, AGE31X))

  FYC$ind = 1  

# Add aggregate sources of payment
  if(year <= 1999)
    FYC <- FYC %>% mutate(TOTTRI03 = TOTCHM03)

  FYC <- FYC %>% mutate(
    TOTOTH03 = TOTOFD03 + TOTSTL03 + TOTOPR03 + TOTOPU03 + TOTOSR03,
    TOTOTZ03 = TOTOTH03 + TOTWCP03 + TOTVA03,
    TOTPTR03 = TOTPRV03 + TOTTRI03)

# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(ind, DUPERSID, PERWT03F, VARSTR, VARPSU)

# Load event files
  RX <- read.xport('C:/MEPS/h77a.ssp')
  DVT <- read.xport('C:/MEPS/h77b.ssp')
  IPT <- read.xport('C:/MEPS/h77d.ssp')
  ERT <- read.xport('C:/MEPS/h77e.ssp')
  OPT <- read.xport('C:/MEPS/h77f.ssp')
  OBV <- read.xport('C:/MEPS/h77g.ssp')
  HHT <- read.xport('C:/MEPS/h77h.ssp')

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
    summarise_at(vars(RXSF03X:RXXP03X),sum) %>%
    ungroup

# Stack events (dental visits and other medical not collected for events)
  stacked_events <- stack_events(RX, IPT, ERT, OPT, OBV, HHT, keep.vars = c('SEEDOC','event_v2X'))

  stacked_events <- stacked_events %>%
    mutate(event = data,
           PR03X = PV03X + TR03X,
           OZ03X = OF03X + SL03X + OT03X + OR03X + OU03X + WC03X + VA03X)

# Read in event-condition linking file
  clink1 = read.xport('C:/MEPS/h77if1.ssp') %>%
    select(DUPERSID,CONDIDX,EVNTIDX)

# Read in conditions file and merge with condition_codes, link file
  cond <- read.xport('C:/MEPS/h78.ssp') %>%
    select(DUPERSID, CONDIDX, CCCODEX) %>%
    mutate(CCS_Codes = as.numeric(as.character(CCCODEX))) %>%
    left_join(condition_codes, by = "CCS_Codes") %>%
    full_join(clink1, by = c("DUPERSID", "CONDIDX")) %>%
    distinct(DUPERSID, EVNTIDX, Condition, .keep_all=T)

# Merge events with conditions-link file and FYCsub
  all_events <- full_join(stacked_events, cond, by=c("DUPERSID","EVNTIDX")) %>%
    filter(!is.na(Condition),XP03X >= 0) %>%
    mutate(count = 1) %>%
    full_join(FYCsub, by = "DUPERSID")

# Sum by person, condition, across event
all_pers <- all_events %>%
  group_by(ind, DUPERSID, VARSTR, VARPSU, PERWT03F, Condition, count) %>%
  summarize_at(vars(SF03X, PR03X, MR03X, MD03X, OZ03X, XP03X),sum) %>% ungroup

PERSdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT03F,
  data = all_pers,
  nest = TRUE)

svyby(~XP03X + SF03X + MR03X + MD03X + PR03X + OZ03X, by = ~Condition, FUN = svymean, design = PERSdsgn)
