# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h155.ssp');
  year <- 2012

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU12, VARSTR=VARSTR12)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT12F = WTDPER12)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE12X, AGE42X, AGE31X))

  FYC$ind = 1  

# Add aggregate event variables
  FYC <- FYC %>% mutate(
    HHTEXP12 = HHAEXP12 + HHNEXP12, # Home Health Agency + Independent providers
    ERTEXP12 = ERFEXP12 + ERDEXP12, # Doctor + Facility Expenses for OP, ER, IP events
    IPTEXP12 = IPFEXP12 + IPDEXP12,
    OPTEXP12 = OPFEXP12 + OPDEXP12, # All Outpatient
    OPYEXP12 = OPVEXP12 + OPSEXP12, # Physician only
    OPZEXP12 = OPOEXP12 + OPPEXP12, # Non-physician only
    OMAEXP12 = VISEXP12 + OTHEXP12) # Other medical equipment and services

  FYC <- FYC %>% mutate(
    TOTUSE12 = ((DVTOT12 > 0) + (RXTOT12 > 0) + (OBTOTV12 > 0) +
                  (OPTOTV12 > 0) + (ERTOT12 > 0) + (IPDIS12 > 0) +
                  (HHTOTD12 > 0) + (OMAEXP12 > 0))
  )

# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(ind, DUPERSID, PERWT12F, VARSTR, VARPSU)

# Load event files
  RX <- read.xport('C:/MEPS/h152a.ssp')
  DVT <- read.xport('C:/MEPS/h152b.ssp')
  IPT <- read.xport('C:/MEPS/h152d.ssp')
  ERT <- read.xport('C:/MEPS/h152e.ssp')
  OPT <- read.xport('C:/MEPS/h152f.ssp')
  OBV <- read.xport('C:/MEPS/h152g.ssp')
  HHT <- read.xport('C:/MEPS/h152h.ssp')

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
    summarise_at(vars(RXSF12X:RXXP12X),sum) %>%
    ungroup

# Stack events (dental visits and other medical not collected for events)
  stacked_events <- stack_events(RX, IPT, ERT, OPT, OBV, HHT, keep.vars = c('SEEDOC','event_v2X'))

  stacked_events <- stacked_events %>%
    mutate(event = data,
           PR12X = PV12X + TR12X,
           OZ12X = OF12X + SL12X + OT12X + OR12X + OU12X + WC12X + VA12X)

# Read in event-condition linking file
  clink1 = read.xport('C:/MEPS/h152if1.ssp') %>%
    select(DUPERSID,CONDIDX,EVNTIDX)

# Read in conditions file and merge with condition_codes, link file
  cond <- read.xport('C:/MEPS/h154.ssp') %>%
    select(DUPERSID, CONDIDX, CCCODEX) %>%
    mutate(CCS_Codes = as.numeric(as.character(CCCODEX))) %>%
    left_join(condition_codes, by = "CCS_Codes") %>%
    full_join(clink1, by = c("DUPERSID", "CONDIDX")) %>%
    distinct(DUPERSID, EVNTIDX, Condition, .keep_all=T)

# Merge events with conditions-link file and FYCsub
  all_events <- full_join(stacked_events, cond, by=c("DUPERSID","EVNTIDX")) %>%
    filter(!is.na(Condition),XP12X >= 0) %>%
    mutate(count = 1) %>%
    full_join(FYCsub, by = "DUPERSID")

# Sum by person, condition, event;
all_persev <- all_events %>%
  group_by(ind, DUPERSID, VARSTR, VARPSU, PERWT12F, Condition, event, count) %>%
  summarize_at(vars(SF12X, PR12X, MR12X, MD12X, OZ12X, XP12X),sum) %>% ungroup

PERSevnt <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT12F,
  data = all_persev,
  nest = TRUE)

svyby(~count, by = ~Condition + event, FUN = svytotal, design = PERSevnt)
