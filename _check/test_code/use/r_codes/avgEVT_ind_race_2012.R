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

# Race / ethnicity
  # Starting in 2012, RACETHX replaced RACEX;
  if(year >= 2012){
    FYC <- FYC %>%
      mutate(white_oth=F,
        hisp   = (RACETHX == 1),
        white  = (RACETHX == 2),
        black  = (RACETHX == 3),
        native = (RACETHX > 3 & RACEV1X %in% c(3,6)),
        asian  = (RACETHX > 3 & RACEV1X %in% c(4,5)))

  }else if(year >= 2002){
    FYC <- FYC %>%
      mutate(white_oth=0,
        hisp   = (RACETHNX == 1),
        white  = (RACETHNX == 4 & RACEX == 1),
        black  = (RACETHNX == 2),
        native = (RACETHNX >= 3 & RACEX %in% c(3,6)),
        asian  = (RACETHNX >= 3 & RACEX %in% c(4,5)))

  }else{
    FYC <- FYC %>%
      mutate(
        hisp = (RACETHNX == 1),
        black = (RACETHNX == 2),
        white_oth = (RACETHNX == 3),
        white = 0,native=0,asian=0)
  }

  FYC <- FYC %>% mutate(
    race = 1*hisp + 2*white + 3*black + 4*native + 5*asian + 9*white_oth,
    race = recode_factor(race, .default = "Missing",
      "1" = "Hispanic",
      "2" = "White",
      "3" = "Black",
      "4" = "Amer. Indian, AK Native, or mult. races",
      "5" = "Asian, Hawaiian, or Pacific Islander",
      "9" = "White and other"))

# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(ind,race, DUPERSID, PERWT12F, VARSTR, VARPSU)

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

# Stack events
  stacked_events <- stack_events(RX, DVT, IPT, ERT, OPT, OBV, HHT,
    keep.vars = c('SEEDOC','event_v2X'))

  stacked_events <- stacked_events %>%
    mutate(event = data,
           PR12X = PV12X + TR12X,
           OZ12X = OF12X + SL12X + OT12X + OR12X + OU12X + WC12X + VA12X) %>%
    select(DUPERSID, event, event_v2X, SEEDOC,
      XP12X, SF12X, MR12X, MD12X, PR12X, OZ12X)

pers_events <- stacked_events %>%
  group_by(DUPERSID) %>%
  summarise(ANY = sum(XP12X >= 0),
            EXP = sum(XP12X > 0),
            SLF = sum(SF12X > 0),
            MCR = sum(MR12X > 0),
            MCD = sum(MD12X > 0),
            PTR = sum(PR12X > 0),
            OTZ = sum(OZ12X > 0)) %>%
  ungroup

n_events <- full_join(pers_events,FYCsub,by='DUPERSID') %>%
  mutate_at(vars(ANY,EXP,SLF,MCR,MCD,PTR,OTZ),
            function(x) ifelse(is.na(x),0,x))

nEVTdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT12F,
  data = n_events,
  nest = TRUE)

svyby(~ANY, FUN=svymean, by = ~ind + race, design = nEVTdsgn)
