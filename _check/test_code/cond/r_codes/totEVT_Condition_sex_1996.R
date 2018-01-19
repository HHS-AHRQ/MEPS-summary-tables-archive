# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h12.ssp');
  year <- 1996

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU96, VARSTR=VARSTR96)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT96F = WTDPER96)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE96X, AGE42X, AGE31X))

  FYC$ind = 1  

# Sex
  FYC <- FYC %>%
    mutate(sex = recode_factor(SEX, .default = "Missing",
      "1" = "Male",
      "2" = "Female"))

# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(sex,ind, DUPERSID, PERWT96F, VARSTR, VARPSU)

# Load event files
  RX <- read.xport('C:/MEPS/hc10a.ssp')
  DVT <- read.xport('C:/MEPS/hc10bf1.ssp')
  IPT <- read.xport('C:/MEPS/hc10df1.ssp')
  ERT <- read.xport('C:/MEPS/hc10ef1.ssp')
  OPT <- read.xport('C:/MEPS/hc10ff1.ssp')
  OBV <- read.xport('C:/MEPS/hc10gf1.ssp')
  HHT <- read.xport('C:/MEPS/hc10hf1.ssp')

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
    summarise_at(vars(RXSF96X:RXXP96X),sum) %>%
    ungroup

# Stack events (dental visits and other medical not collected for events)
  stacked_events <- stack_events(RX, IPT, ERT, OPT, OBV, HHT, keep.vars = c('SEEDOC','event_v2X'))

  stacked_events <- stacked_events %>%
    mutate(event = data,
           PR96X = PV96X + TR96X,
           OZ96X = OF96X + SL96X + OT96X + OR96X + OU96X + WC96X + VA96X)

# Read in event-condition linking file
  clink1 = read.xport('C:/MEPS/hc10if1.ssp') %>%
    select(DUPERSID,CONDIDX,EVNTIDX)

# Read in conditions file and merge with condition_codes, link file
  cond <- read.xport('C:/MEPS/hc006r.ssp') %>%
    select(DUPERSID, CONDIDX, CCCODEX) %>%
    mutate(CCS_Codes = as.numeric(as.character(CCCODEX))) %>%
    left_join(condition_codes, by = "CCS_Codes") %>%
    full_join(clink1, by = c("DUPERSID", "CONDIDX")) %>%
    distinct(DUPERSID, EVNTIDX, Condition, .keep_all=T)

# Merge events with conditions-link file and FYCsub
  all_events <- full_join(stacked_events, cond, by=c("DUPERSID","EVNTIDX")) %>%
    filter(!is.na(Condition),XP96X >= 0) %>%
    mutate(count = 1) %>%
    full_join(FYCsub, by = "DUPERSID")

EVNTdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT96F,           
  data = all_events,
  nest = TRUE) 

svyby(~count, by = ~Condition + sex, FUN = svytotal, design = EVNTdsgn)
