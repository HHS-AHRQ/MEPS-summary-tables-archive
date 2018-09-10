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

# Insurance coverage
# To compute for all insurance categories, replace 'insurance' in the 'svyby' function with 'insurance_v2X'
  if(year == 1996){
    FYC <- FYC %>%
      mutate(MCDEV96 = MCDEVER, MCREV96 = MCREVER,
             OPAEV96 = OPAEVER, OPBEV96 = OPBEVER)
  }

  if(year < 2011){
    FYC <- FYC %>%
      mutate(
        public   = (MCDEV.yy.==1|OPAEV.yy.==1|OPBEV.yy.==1),
        medicare = (MCREV.yy.==1),
        private  = (INSCOV.yy.==1),

        mcr_priv = (medicare &  private),
        mcr_pub  = (medicare & !private & public),
        mcr_only = (medicare & !private & !public),
        no_mcr   = (!medicare),

        ins_gt65 = 4*mcr_only + 5*mcr_priv + 6*mcr_pub + 7*no_mcr,
        INSURC.yy. = ifelse(AGELAST < 65, INSCOV.yy., ins_gt65)
      )
  }

  FYC <- FYC %>%
    mutate(insurance = recode_factor(INSCOV.yy., .default = "Missing", .missing = "Missing", 
      "1" = "Any private, all ages",
      "2" = "Public only, all ages",
      "3" = "Uninsured, all ages")) %>%
    mutate(insurance_v2X = recode_factor(INSURC.yy., .default = "Missing", .missing = "Missing",
      "1" = "<65, Any private",
      "2" = "<65, Public only",
      "3" = "<65, Uninsured",
      "4" = "65+, Medicare only",
      "5" = "65+, Medicare and private",
      "6" = "65+, Medicare and other public",
      "7" = "65+, No medicare",
      "8" = "65+, No medicare"))

# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(insurance,region,ind, DUPERSID, PERWT.yy.F, VARSTR, VARPSU)

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

pers_events <- stacked_events %>%
  group_by(DUPERSID) %>%
  summarise(ANY = sum(XP.yy.X >= 0),
            EXP = sum(XP.yy.X > 0),
            SLF = sum(SF.yy.X > 0),
            MCR = sum(MR.yy.X > 0),
            MCD = sum(MD.yy.X > 0),
            PTR = sum(PR.yy.X > 0),
            OTZ = sum(OZ.yy.X > 0)) %>%
  ungroup

n_events <- full_join(pers_events,FYCsub,by='DUPERSID') %>%
  mutate_at(vars(ANY,EXP,SLF,MCR,MCD,PTR,OTZ),
            function(x) ifelse(is.na(x),0,x))

nEVTdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT.yy.F,
  data = n_events,
  nest = TRUE)

results <- svyby(~ANY, FUN=svymean, by = ~insurance + region, design = nEVTdsgn)
print(results)
