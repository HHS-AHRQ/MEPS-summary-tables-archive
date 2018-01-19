# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h20.ssp');
  year <- 1997

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU97, VARSTR=VARSTR97)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT97F = WTDPER97)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE97X, AGE42X, AGE31X))

  FYC$ind = 1  

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
        public   = (MCDEV97==1|OPAEV97==1|OPBEV97==1),
        medicare = (MCREV97==1),
        private  = (INSCOV97==1),

        mcr_priv = (medicare &  private),
        mcr_pub  = (medicare & !private & public),
        mcr_only = (medicare & !private & !public),
        no_mcr   = (!medicare),

        ins_gt65 = 4*mcr_only + 5*mcr_priv + 6*mcr_pub + 7*no_mcr,
        INSURC97 = ifelse(AGELAST < 65, INSCOV97, ins_gt65)
      )
  }

  FYC <- FYC %>%
    mutate(insurance = recode_factor(INSCOV97, .default = "Missing",
      "1" = "Any private, all ages",
      "2" = "Public only, all ages",
      "3" = "Uninsured, all ages")) %>%
    mutate(insurance_v2X = recode_factor(INSURC97, .default = "Missing",
      "1" = "<65, Any private",
      "2" = "<65, Public only",
      "3" = "<65, Uninsured",
      "4" = "65+, Medicare only",
      "5" = "65+, Medicare and private",
      "6" = "65+, Medicare and other public",
      "7" = "65+, No medicare",
      "8" = "65+, No medicare"))

# Education
  if(year <= 1998){
    FYC <- FYC %>% mutate(EDUCYR = EDUCYR97)
  }else if(year <= 2004){
    FYC <- FYC %>% mutate(EDUCYR = EDUCYEAR)
  }

  if(year >= 2012){
    FYC <- FYC %>%
      mutate(
        less_than_hs = (0 <= EDRECODE & EDRECODE < 13),
        high_school  = (EDRECODE == 13),
        some_college = (EDRECODE > 13))

  }else{
    FYC <- FYC %>%
      mutate(
        less_than_hs = (0 <= EDUCYR & EDUCYR < 12),
        high_school  = (EDUCYR == 12),
        some_college = (EDUCYR > 12))
  }

  FYC <- FYC %>% mutate(
    education = 1*less_than_hs + 2*high_school + 3*some_college,
    education = replace(education, AGELAST < 18, 9),
    education = recode_factor(education, .default = "Missing",
      "1" = "Less than high school",
      "2" = "High school",
      "3" = "Some college",
      "9" = "Inapplicable (age < 18)",
      "0" = "Missing"))

# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(education,insurance,ind, DUPERSID, PERWT97F, VARSTR, VARPSU)

# Load event files
  RX <- read.xport('C:/MEPS/h16a.ssp')
  DVT <- read.xport('C:/MEPS/hc16bf1.ssp')
  IPT <- read.xport('C:/MEPS/hc16df1.ssp')
  ERT <- read.xport('C:/MEPS/hc16ef1.ssp')
  OPT <- read.xport('C:/MEPS/hc16ff1.ssp')
  OBV <- read.xport('C:/MEPS/hc16gf1.ssp')
  HHT <- read.xport('C:/MEPS/hc16hf1.ssp')

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
           PR97X = PV97X + TR97X,
           OZ97X = OF97X + SL97X + OT97X + OR97X + OU97X + WC97X + VA97X) %>%
    select(DUPERSID, event, event_v2X, SEEDOC,
      XP97X, SF97X, MR97X, MD97X, PR97X, OZ97X)

pers_events <- stacked_events %>%
  group_by(DUPERSID) %>%
  summarise(ANY = sum(XP97X >= 0),
            EXP = sum(XP97X > 0),
            SLF = sum(SF97X > 0),
            MCR = sum(MR97X > 0),
            MCD = sum(MD97X > 0),
            PTR = sum(PR97X > 0),
            OTZ = sum(OZ97X > 0)) %>%
  ungroup

n_events <- full_join(pers_events,FYCsub,by='DUPERSID') %>%
  mutate_at(vars(ANY,EXP,SLF,MCR,MCD,PTR,OTZ),
            function(x) ifelse(is.na(x),0,x))

nEVTdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT97F,
  data = n_events,
  nest = TRUE)

svyby(~ANY, FUN=svymean, by = ~education + insurance, design = nEVTdsgn)
