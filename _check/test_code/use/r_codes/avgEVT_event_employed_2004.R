# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h89.ssp');
  year <- 2004

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU04, VARSTR=VARSTR04)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT04F = WTDPER04)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE04X, AGE42X, AGE31X))

  FYC$ind = 1  

# Employment Status
  if(year == 1996)
    FYC <- FYC %>% mutate(EMPST53 = EMPST96, EMPST42 = EMPST2, EMPST31 = EMPST1)

  FYC <- FYC %>%
    mutate_at(vars(EMPST53, EMPST42, EMPST31), funs(replace(., .< 0, NA))) %>%
    mutate(employ_last = coalesce(EMPST53, EMPST42, EMPST31))

  FYC <- FYC %>% mutate(
    employed = 1*(employ_last==1) + 2*(employ_last > 1),
    employed = replace(employed, is.na(employed) & AGELAST < 16, 9),
    employed = recode_factor(employed, .default = "Missing",
      "1" = "Employed",
      "2" = "Not employed",
      "9" = "Inapplicable (age < 16)"))

# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(employed,ind, DUPERSID, PERWT04F, VARSTR, VARPSU)

# Load event files
  RX <- read.xport('C:/MEPS/h85a.ssp')
  DVT <- read.xport('C:/MEPS/h85b.ssp')
  IPT <- read.xport('C:/MEPS/h85d.ssp')
  ERT <- read.xport('C:/MEPS/h85e.ssp')
  OPT <- read.xport('C:/MEPS/h85f.ssp')
  OBV <- read.xport('C:/MEPS/h85g.ssp')
  HHT <- read.xport('C:/MEPS/h85h.ssp')

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
           PR04X = PV04X + TR04X,
           OZ04X = OF04X + SL04X + OT04X + OR04X + OU04X + WC04X + VA04X) %>%
    select(DUPERSID, event, event_v2X, SEEDOC,
      XP04X, SF04X, MR04X, MD04X, PR04X, OZ04X)

pers_events <- stacked_events %>%
  group_by(DUPERSID) %>%
  summarise(ANY = sum(XP04X >= 0),
            EXP = sum(XP04X > 0),
            SLF = sum(SF04X > 0),
            MCR = sum(MR04X > 0),
            MCD = sum(MD04X > 0),
            PTR = sum(PR04X > 0),
            OTZ = sum(OZ04X > 0)) %>%
  ungroup

n_events <- full_join(pers_events,FYCsub,by='DUPERSID') %>%
  mutate_at(vars(ANY,EXP,SLF,MCR,MCD,PTR,OTZ),
            function(x) ifelse(is.na(x),0,x))

nEVTdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT04F,
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
      mutate(PR04X = PV04X + TR04X,
             OZ04X = OF04X + SL04X + OT04X + OR04X + OU04X + WC04X + VA04X)

    pers_events <- df %>%
      group_by(DUPERSID) %>%
      summarise(ANY = sum(XP04X >= 0),
                EXP = sum(XP04X > 0),
                SLF = sum(SF04X > 0),
                MCR = sum(MR04X > 0),
                MCD = sum(MD04X > 0),
                PTR = sum(PR04X > 0),
                OTZ = sum(OZ04X > 0))

    n_events <- full_join(pers_events,FYCsub,by="DUPERSID") %>%
      mutate_at(vars(ANY, EXP, SLF, MCR, MCD, PTR, OTZ),
                function(x) ifelse(is.na(x),0,x))

    EVdsgn <- svydesign(
      id = ~VARPSU,
      strata = ~VARSTR,
      weights = ~PERWT04F,
      data = n_events,
      nest = TRUE)

    results[[key]] <- svyby(~ANY, by = ~employed, FUN = svymean, design = EVdsgn)
  }
  print(results)
