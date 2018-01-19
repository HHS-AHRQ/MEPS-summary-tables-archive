# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h147.ssp');
  year <- 2011

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU11, VARSTR=VARSTR11)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT11F = WTDPER11)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE11X, AGE42X, AGE31X))

  FYC$ind = 1  

# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(ind, DUPERSID, PERWT11F, VARSTR, VARPSU)

# Load event files
  RX <- read.xport('C:/MEPS/h144a.ssp')
  DVT <- read.xport('C:/MEPS/h144b.ssp')
  IPT <- read.xport('C:/MEPS/h144d.ssp')
  ERT <- read.xport('C:/MEPS/h144e.ssp')
  OPT <- read.xport('C:/MEPS/h144f.ssp')
  OBV <- read.xport('C:/MEPS/h144g.ssp')
  HHT <- read.xport('C:/MEPS/h144h.ssp')

# Define sub-levels for office-based and outpatient
  OBV <- OBV %>%
    mutate(event_v2X = recode_factor(
      SEEDOC, .default = 'Missing', '1' = 'OBD', '2' = 'OBO'))

  OPT <- OPT %>%
    mutate(event_v2X = recode_factor(
      SEEDOC, .default = 'Missing', '1' = 'OPY', '2' = 'OPZ'))

# Stack events
  stacked_events <- stack_events(RX, DVT, IPT, ERT, OPT, OBV, HHT,
    keep.vars = c('SEEDOC','event_v2X'))

  stacked_events <- stacked_events %>%
    mutate(event = data,
           PR11X = PV11X + TR11X,
           OZ11X = OF11X + SL11X + OT11X + OR11X + OU11X + WC11X + VA11X) %>%
    select(DUPERSID, event, event_v2X, SEEDOC,
      XP11X, SF11X, MR11X, MD11X, PR11X, OZ11X)

pers_events <- stacked_events %>%
  group_by(DUPERSID) %>%
  summarise(ANY = sum(XP11X >= 0),
            EXP = sum(XP11X > 0),
            SLF = sum(SF11X > 0),
            MCR = sum(MR11X > 0),
            MCD = sum(MD11X > 0),
            PTR = sum(PR11X > 0),
            OTZ = sum(OZ11X > 0)) %>%
  ungroup

n_events <- full_join(pers_events,FYCsub,by='DUPERSID') %>%
  mutate_at(vars(ANY,EXP,SLF,MCR,MCD,PTR,OTZ),
            function(x) ifelse(is.na(x),0,x))

nEVTdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT11F,
  data = n_events,
  nest = TRUE)

# Create datasets for physician / non-physician office-based / outpatient events
  OBD = OBV %>% filter(event_v2X == "OBD")
  OBO = OBV %>% filter(event_v2X == "OBO")
  OPY = OPT %>% filter(event_v2X == "OPY")
  OPZ = OPT %>% filter(event_v2X == "OPZ")

  events <- c("DVT", "RX",  "OBV", "OBD", "OBO", "OPT",
              "OPY", "OPZ", "ERT", "IPT", "HHT")

# Run for each event dataset
  results <- list()
  for(ev in events) {
    key <- ev
    df <- get(key) %>%
      rm_evnt_key() %>%
      add_total_sops() %>%
      mutate(PR11X = PV11X + TR11X,
             OZ11X = OF11X + SL11X + OT11X + OR11X + OU11X + WC11X + VA11X)

    pers_events <- df %>%
      group_by(DUPERSID) %>%
      summarise(ANY = sum(XP11X >= 0),
                EXP = sum(XP11X > 0),
                SLF = sum(SF11X > 0),
                MCR = sum(MR11X > 0),
                MCD = sum(MD11X > 0),
                PTR = sum(PR11X > 0),
                OTZ = sum(OZ11X > 0))

    n_events <- full_join(pers_events,FYCsub,by="DUPERSID") %>%
      mutate_at(vars(ANY, EXP, SLF, MCR, MCD, PTR, OTZ),
                function(x) ifelse(is.na(x),0,x))

    EVdsgn <- svydesign(
      id = ~VARPSU,
      strata = ~VARSTR,
      weights = ~PERWT11F,
      data = n_events,
      nest = TRUE)

    results[[key]] <- svyby(~EXP + SLF + MCR + MCD + PTR + OTZ, by = ~ind, FUN = svymean, design = EVdsgn)
  }
  print(results)
