# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/.FYC..ssp');
  year <- .year.

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU.yy., VARSTR=VARSTR.yy.)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT.yy.F = WTDPER.yy.)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE.yy.X, AGE42X, AGE31X))

  FYC$ind = 1  

# Census region
  if(year == 1996)
    FYC <- FYC %>% mutate(REGION42 = REGION2, REGION31 = REGION1)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("REGION")), funs(replace(., .< 0, NA))) %>%
    mutate(region = coalesce(REGION.yy., REGION42, REGION31)) %>%
    mutate(region = recode_factor(region, .default = "Missing", .missing = "Missing", 
      "1" = "Northeast",
      "2" = "Midwest",
      "3" = "South",
      "4" = "West"))

# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(region,ind, DUPERSID, PERWT.yy.F, VARSTR, VARPSU)

# Load event files
  RX <- read.xport('C:/MEPS/.RX..ssp')
  DVT <- read.xport('C:/MEPS/.DV..ssp')
  IPT <- read.xport('C:/MEPS/.IP..ssp')
  ERT <- read.xport('C:/MEPS/.ER..ssp')
  OPT <- read.xport('C:/MEPS/.OP..ssp')
  OBV <- read.xport('C:/MEPS/.OB..ssp')
  HHT <- read.xport('C:/MEPS/.HH..ssp')

# Define sub-levels for office-based and outpatient
#  To compute estimates for these sub-events, replace 'event' with 'event_v2X'
#  in the 'svyby' statement below, when applicable
  OBV <- OBV %>%
    mutate(event_v2X = recode_factor(
      SEEDOC, .default = 'Missing', .missing = "Missing", '1' = 'OBD', '2' = 'OBO'))

  OPT <- OPT %>%
    mutate(event_v2X = recode_factor(
      SEEDOC, .default = 'Missing', .missing = "Missing", '1' = 'OPY', '2' = 'OPZ'))

# Stack events
  stacked_events <- stack_events(RX, DVT, IPT, ERT, OPT, OBV, HHT,
    keep.vars = c('SEEDOC','event_v2X'))

  stacked_events <- stacked_events %>%
    mutate(event = data,
           PR.yy.X = PV.yy.X + TR.yy.X,
           OZ.yy.X = OF.yy.X + SL.yy.X + OT.yy.X + OR.yy.X + OU.yy.X + WC.yy.X + VA.yy.X) %>%
    select(DUPERSID, event, event_v2X, SEEDOC,
      XP.yy.X, SF.yy.X, MR.yy.X, MD.yy.X, PR.yy.X, OZ.yy.X)

  EVENTS <- stacked_events %>% full_join(FYCsub, by='DUPERSID')

EVNTdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT.yy.F,           
  data = EVENTS,
  nest = TRUE)

results <- svyby(~XP.yy.X, FUN=svymean, by = ~region + event, design = subset(EVNTdsgn, XP.yy.X >= 0))
print(results)
