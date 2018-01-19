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

  EVENTS <- stacked_events %>% full_join(FYCsub, by='DUPERSID')

EVNTdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT11F,           
  data = EVENTS,
  nest = TRUE)

# Loop over sources of payment
  sops <- c("XP", "SF", "PR", "MR", "MD", "OZ")
  results <- list()
  for(sp in sops) {
    key <- paste0(sp, "11X")
    formula <- as.formula(sprintf("~%s", key))
    results[[key]] <- svyby(formula, FUN = svymean, by = ~ind + event,
      design = subset(EVNTdsgn, EVENTS[[key]] >= 0))
  }
  print(results)
