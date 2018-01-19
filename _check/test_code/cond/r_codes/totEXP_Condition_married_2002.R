# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h70.ssp');
  year <- 2002

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU02, VARSTR=VARSTR02)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT02F = WTDPER02)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE02X, AGE42X, AGE31X))

  FYC$ind = 1  

# Marital status
  if(year == 1996){
    FYC <- FYC %>%
      mutate(MARRY42X = ifelse(MARRY2X <= 6, MARRY2X, MARRY2X-6),
             MARRY31X = ifelse(MARRY1X <= 6, MARRY1X, MARRY1X-6))
  }

  FYC <- FYC %>%
    mutate_at(vars(starts_with("MARRY")), funs(replace(., .< 0, NA))) %>%
    mutate(married = coalesce(MARRY02X, MARRY42X, MARRY31X)) %>%
    mutate(married = recode_factor(married, .default = "Missing",
      "1" = "Married",
      "2" = "Widowed",
      "3" = "Divorced",
      "4" = "Separated",
      "5" = "Never married",
      "6" = "Inapplicable (age < 16)"))

# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(married,ind, DUPERSID, PERWT02F, VARSTR, VARPSU)

# Load event files
  RX <- read.xport('C:/MEPS/h67a.ssp')
  DVT <- read.xport('C:/MEPS/h67b.ssp')
  IPT <- read.xport('C:/MEPS/h67d.ssp')
  ERT <- read.xport('C:/MEPS/h67e.ssp')
  OPT <- read.xport('C:/MEPS/h67f.ssp')
  OBV <- read.xport('C:/MEPS/h67g.ssp')
  HHT <- read.xport('C:/MEPS/h67h.ssp')

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
    summarise_at(vars(RXSF02X:RXXP02X),sum) %>%
    ungroup

# Stack events (dental visits and other medical not collected for events)
  stacked_events <- stack_events(RX, IPT, ERT, OPT, OBV, HHT, keep.vars = c('SEEDOC','event_v2X'))

  stacked_events <- stacked_events %>%
    mutate(event = data,
           PR02X = PV02X + TR02X,
           OZ02X = OF02X + SL02X + OT02X + OR02X + OU02X + WC02X + VA02X)

# Read in event-condition linking file
  clink1 = read.xport('C:/MEPS/h67if1.ssp') %>%
    select(DUPERSID,CONDIDX,EVNTIDX)

# Read in conditions file and merge with condition_codes, link file
  cond <- read.xport('C:/MEPS/h69.ssp') %>%
    select(DUPERSID, CONDIDX, CCCODEX) %>%
    mutate(CCS_Codes = as.numeric(as.character(CCCODEX))) %>%
    left_join(condition_codes, by = "CCS_Codes") %>%
    full_join(clink1, by = c("DUPERSID", "CONDIDX")) %>%
    distinct(DUPERSID, EVNTIDX, Condition, .keep_all=T)

# Merge events with conditions-link file and FYCsub
  all_events <- full_join(stacked_events, cond, by=c("DUPERSID","EVNTIDX")) %>%
    filter(!is.na(Condition),XP02X >= 0) %>%
    mutate(count = 1) %>%
    full_join(FYCsub, by = "DUPERSID")

EVNTdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT02F,           
  data = all_events,
  nest = TRUE) 

svyby(~XP02X, by = ~Condition + married, FUN = svytotal, design = EVNTdsgn)
