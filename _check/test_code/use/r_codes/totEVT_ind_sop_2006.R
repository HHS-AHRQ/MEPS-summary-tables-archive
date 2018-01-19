# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h105.ssp');
  year <- 2006

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU06, VARSTR=VARSTR06)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT06F = WTDPER06)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE06X, AGE42X, AGE31X))

  FYC$ind = 1  

# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(ind, DUPERSID, PERWT06F, VARSTR, VARPSU)

# Load event files
  RX <- read.xport('C:/MEPS/h102a.ssp')
  DVT <- read.xport('C:/MEPS/h102b.ssp')
  IPT <- read.xport('C:/MEPS/h102d.ssp')
  ERT <- read.xport('C:/MEPS/h102e.ssp')
  OPT <- read.xport('C:/MEPS/h102f.ssp')
  OBV <- read.xport('C:/MEPS/h102g.ssp')
  HHT <- read.xport('C:/MEPS/h102h.ssp')

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
           PR06X = PV06X + TR06X,
           OZ06X = OF06X + SL06X + OT06X + OR06X + OU06X + WC06X + VA06X) %>%
    select(DUPERSID, event, event_v2X, SEEDOC,
      XP06X, SF06X, MR06X, MD06X, PR06X, OZ06X)

  EVENTS <- stacked_events %>% full_join(FYCsub, by='DUPERSID')

EVNTdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT06F,           
  data = EVENTS,
  nest = TRUE)

# Loop over sources of payment
  sops <- c("XP", "SF", "PR", "MR", "MD", "OZ")
  results <- list()
  for(sp in sops) {
    key <- paste0(sp, "06X")
    formula <- as.formula(sprintf("~(%s > 0)", key))
    results[[key]] <- svyby(formula, FUN = svytotal, by = ~ind,
      design = subset(EVNTdsgn, EVENTS[[key]] >= 0))
  }
  print(results)
