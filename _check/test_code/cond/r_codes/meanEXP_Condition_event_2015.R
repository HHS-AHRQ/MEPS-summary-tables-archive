# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h181.ssp');
  year <- 2015

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU15, VARSTR=VARSTR15)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT15F = WTDPER15)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE15X, AGE42X, AGE31X))

  FYC$ind = 1  

# Add aggregate event variables
  FYC <- FYC %>% mutate(
    HHTEXP15 = HHAEXP15 + HHNEXP15, # Home Health Agency + Independent providers
    ERTEXP15 = ERFEXP15 + ERDEXP15, # Doctor + Facility Expenses for OP, ER, IP events
    IPTEXP15 = IPFEXP15 + IPDEXP15,
    OPTEXP15 = OPFEXP15 + OPDEXP15, # All Outpatient
    OPYEXP15 = OPVEXP15 + OPSEXP15, # Physician only
    OPZEXP15 = OPOEXP15 + OPPEXP15, # Non-physician only
    OMAEXP15 = VISEXP15 + OTHEXP15) # Other medical equipment and services

  FYC <- FYC %>% mutate(
    TOTUSE15 = ((DVTOT15 > 0) + (RXTOT15 > 0) + (OBTOTV15 > 0) +
                  (OPTOTV15 > 0) + (ERTOT15 > 0) + (IPDIS15 > 0) +
                  (HHTOTD15 > 0) + (OMAEXP15 > 0))
  )

# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(ind, DUPERSID, PERWT15F, VARSTR, VARPSU)

# Load event files
  RX <- read.xport('C:/MEPS/h178a.ssp')
  DVT <- read.xport('C:/MEPS/h178b.ssp')
  IPT <- read.xport('C:/MEPS/h178d.ssp')
  ERT <- read.xport('C:/MEPS/h178e.ssp')
  OPT <- read.xport('C:/MEPS/h178f.ssp')
  OBV <- read.xport('C:/MEPS/h178g.ssp')
  HHT <- read.xport('C:/MEPS/h178h.ssp')

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
    summarise_at(vars(RXSF15X:RXXP15X),sum) %>%
    ungroup

# Stack events (dental visits and other medical not collected for events)
  stacked_events <- stack_events(RX, IPT, ERT, OPT, OBV, HHT, keep.vars = c('SEEDOC','event_v2X'))

  stacked_events <- stacked_events %>%
    mutate(event = data,
           PR15X = PV15X + TR15X,
           OZ15X = OF15X + SL15X + OT15X + OR15X + OU15X + WC15X + VA15X)

# Read in event-condition linking file
  clink1 = read.xport('C:/MEPS/h178if1.ssp') %>%
    select(DUPERSID,CONDIDX,EVNTIDX)

# Read in conditions file and merge with condition_codes, link file
  cond <- read.xport('C:/MEPS/h180.ssp') %>%
    select(DUPERSID, CONDIDX, CCCODEX) %>%
    mutate(CCS_Codes = as.numeric(as.character(CCCODEX))) %>%
    left_join(condition_codes, by = "CCS_Codes") %>%
    full_join(clink1, by = c("DUPERSID", "CONDIDX")) %>%
    distinct(DUPERSID, EVNTIDX, Condition, .keep_all=T)

# Merge events with conditions-link file and FYCsub
  all_events <- full_join(stacked_events, cond, by=c("DUPERSID","EVNTIDX")) %>%
    filter(!is.na(Condition),XP15X >= 0) %>%
    mutate(count = 1) %>%
    full_join(FYCsub, by = "DUPERSID")

# Sum by person, condition, event;
all_persev <- all_events %>%
  group_by(ind, DUPERSID, VARSTR, VARPSU, PERWT15F, Condition, event, count) %>%
  summarize_at(vars(SF15X, PR15X, MR15X, MD15X, OZ15X, XP15X),sum) %>% ungroup

PERSevnt <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT15F,
  data = all_persev,
  nest = TRUE)

svyby(~XP15X, by = ~Condition + event,FUN = svymean, design = PERSevnt)
