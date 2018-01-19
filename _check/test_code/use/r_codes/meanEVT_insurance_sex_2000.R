# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h50.ssp');
  year <- 2000

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU00, VARSTR=VARSTR00)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT00F = WTDPER00)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE00X, AGE42X, AGE31X))

  FYC$ind = 1  

# Sex
  FYC <- FYC %>%
    mutate(sex = recode_factor(SEX, .default = "Missing",
      "1" = "Male",
      "2" = "Female"))

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
        public   = (MCDEV00==1|OPAEV00==1|OPBEV00==1),
        medicare = (MCREV00==1),
        private  = (INSCOV00==1),

        mcr_priv = (medicare &  private),
        mcr_pub  = (medicare & !private & public),
        mcr_only = (medicare & !private & !public),
        no_mcr   = (!medicare),

        ins_gt65 = 4*mcr_only + 5*mcr_priv + 6*mcr_pub + 7*no_mcr,
        INSURC00 = ifelse(AGELAST < 65, INSCOV00, ins_gt65)
      )
  }

  FYC <- FYC %>%
    mutate(insurance = recode_factor(INSCOV00, .default = "Missing",
      "1" = "Any private, all ages",
      "2" = "Public only, all ages",
      "3" = "Uninsured, all ages")) %>%
    mutate(insurance_v2X = recode_factor(INSURC00, .default = "Missing",
      "1" = "<65, Any private",
      "2" = "<65, Public only",
      "3" = "<65, Uninsured",
      "4" = "65+, Medicare only",
      "5" = "65+, Medicare and private",
      "6" = "65+, Medicare and other public",
      "7" = "65+, No medicare",
      "8" = "65+, No medicare"))

# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(insurance,sex,ind, DUPERSID, PERWT00F, VARSTR, VARPSU)

# Load event files
  RX <- read.xport('C:/MEPS/h51a.ssp')
  DVT <- read.xport('C:/MEPS/h51b.ssp')
  IPT <- read.xport('C:/MEPS/h51d.ssp')
  ERT <- read.xport('C:/MEPS/h51e.ssp')
  OPT <- read.xport('C:/MEPS/h51f.ssp')
  OBV <- read.xport('C:/MEPS/h51g.ssp')
  HHT <- read.xport('C:/MEPS/h51h.ssp')

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
           PR00X = PV00X + TR00X,
           OZ00X = OF00X + SL00X + OT00X + OR00X + OU00X + WC00X + VA00X) %>%
    select(DUPERSID, event, event_v2X, SEEDOC,
      XP00X, SF00X, MR00X, MD00X, PR00X, OZ00X)

  EVENTS <- stacked_events %>% full_join(FYCsub, by='DUPERSID')

EVNTdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT00F,           
  data = EVENTS,
  nest = TRUE)

svyby(~XP00X, FUN=svymean, by = ~insurance + sex, design = subset(EVNTdsgn, XP00X >= 0))
