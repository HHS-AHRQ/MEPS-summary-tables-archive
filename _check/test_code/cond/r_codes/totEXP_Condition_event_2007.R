# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h113.ssp');
  year <- 2007

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU07, VARSTR=VARSTR07)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT07F = WTDPER07)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE07X, AGE42X, AGE31X))

  FYC$ind = 1  

# Add aggregate event variables
  FYC <- FYC %>% mutate(
    HHTEXP07 = HHAEXP07 + HHNEXP07, # Home Health Agency + Independent providers
    ERTEXP07 = ERFEXP07 + ERDEXP07, # Doctor + Facility Expenses for OP, ER, IP events
    IPTEXP07 = IPFEXP07 + IPDEXP07,
    OPTEXP07 = OPFEXP07 + OPDEXP07, # All Outpatient
    OPYEXP07 = OPVEXP07 + OPSEXP07, # Physician only
    OPZEXP07 = OPOEXP07 + OPPEXP07, # Non-physician only
    OMAEXP07 = VISEXP07 + OTHEXP07) # Other medical equipment and services

  FYC <- FYC %>% mutate(
    TOTUSE07 = ((DVTOT07 > 0) + (RXTOT07 > 0) + (OBTOTV07 > 0) +
                  (OPTOTV07 > 0) + (ERTOT07 > 0) + (IPDIS07 > 0) +
                  (HHTOTD07 > 0) + (OMAEXP07 > 0))
  )

# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(ind, DUPERSID, PERWT07F, VARSTR, VARPSU)

# Load event files
  RX <- read.xport('C:/MEPS/h110a.ssp')
  DVT <- read.xport('C:/MEPS/h110b.ssp')
  IPT <- read.xport('C:/MEPS/h110d.ssp')
  ERT <- read.xport('C:/MEPS/h110e.ssp')
  OPT <- read.xport('C:/MEPS/h110f.ssp')
  OBV <- read.xport('C:/MEPS/h110g.ssp')
  HHT <- read.xport('C:/MEPS/h110h.ssp')

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
    summarise_at(vars(RXSF07X:RXXP07X),sum) %>%
    ungroup

# Stack events (dental visits and other medical not collected for events)
  stacked_events <- stack_events(RX, IPT, ERT, OPT, OBV, HHT, keep.vars = c('SEEDOC','event_v2X'))

  stacked_events <- stacked_events %>%
    mutate(event = data,
           PR07X = PV07X + TR07X,
           OZ07X = OF07X + SL07X + OT07X + OR07X + OU07X + WC07X + VA07X)

# Read in event-condition linking file
  clink1 = read.xport('C:/MEPS/h110if1.ssp') %>%
    select(DUPERSID,CONDIDX,EVNTIDX)

# Read in conditions file and merge with condition_codes, link file
  cond <- read.xport('C:/MEPS/h112.ssp') %>%
    select(DUPERSID, CONDIDX, CCCODEX) %>%
    mutate(CCS_Codes = as.numeric(as.character(CCCODEX))) %>%
    left_join(condition_codes, by = "CCS_Codes") %>%
    full_join(clink1, by = c("DUPERSID", "CONDIDX")) %>%
    distinct(DUPERSID, EVNTIDX, Condition, .keep_all=T)

# Merge events with conditions-link file and FYCsub
  all_events <- full_join(stacked_events, cond, by=c("DUPERSID","EVNTIDX")) %>%
    filter(!is.na(Condition),XP07X >= 0) %>%
    mutate(count = 1) %>%
    full_join(FYCsub, by = "DUPERSID")

# Sum by person, condition, event;
all_persev <- all_events %>%
  group_by(ind, DUPERSID, VARSTR, VARPSU, PERWT07F, Condition, event, count) %>%
  summarize_at(vars(SF07X, PR07X, MR07X, MD07X, OZ07X, XP07X),sum) %>% ungroup

PERSevnt <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT07F,
  data = all_persev,
  nest = TRUE)

svyby(~XP07X, by = ~Condition + event, FUN = svytotal, design = PERSevnt)
