# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h38.ssp');
  year <- 1999

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU99, VARSTR=VARSTR99)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT99F = WTDPER99)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE99X, AGE42X, AGE31X))

  FYC$ind = 1  

# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(ind, DUPERSID, PERWT99F, VARSTR, VARPSU)

# Load event files
  RX <- read.xport('C:/MEPS/h33a.ssp')
  DVT <- read.xport('C:/MEPS/h33b.ssp')
  IPT <- read.xport('C:/MEPS/h33d.ssp')
  ERT <- read.xport('C:/MEPS/h33e.ssp')
  OPT <- read.xport('C:/MEPS/h33f.ssp')
  OBV <- read.xport('C:/MEPS/h33g.ssp')
  HHT <- read.xport('C:/MEPS/h33h.ssp')

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
           PR99X = PV99X + TR99X,
           OZ99X = OF99X + SL99X + OT99X + OR99X + OU99X + WC99X + VA99X) %>%
    select(DUPERSID, event, event_v2X, SEEDOC,
      XP99X, SF99X, MR99X, MD99X, PR99X, OZ99X)

  EVENTS <- stacked_events %>% full_join(FYCsub, by='DUPERSID')

EVNTdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT99F,           
  data = EVENTS,
  nest = TRUE)

# Loop over sources of payment
  sops <- c("XP", "SF", "PR", "MR", "MD", "OZ")
  results <- list()
  for(sp in sops) {
    key <- paste0(sp, "99X")
    formula <- as.formula(sprintf("~(%s > 0)", key))
    results[[key]] <- svyby(formula, FUN = svytotal, by = ~ind + event,
      design = subset(EVNTdsgn, EVENTS[[key]] >= 0))
  }
  print(results)
