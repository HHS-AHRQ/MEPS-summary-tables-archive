# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h138.ssp');
  year <- 2010

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU10, VARSTR=VARSTR10)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT10F = WTDPER10)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE10X, AGE42X, AGE31X))

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
        public   = (MCDEV10==1|OPAEV10==1|OPBEV10==1),
        medicare = (MCREV10==1),
        private  = (INSCOV10==1),

        mcr_priv = (medicare &  private),
        mcr_pub  = (medicare & !private & public),
        mcr_only = (medicare & !private & !public),
        no_mcr   = (!medicare),

        ins_gt65 = 4*mcr_only + 5*mcr_priv + 6*mcr_pub + 7*no_mcr,
        INSURC10 = ifelse(AGELAST < 65, INSCOV10, ins_gt65)
      )
  }

  FYC <- FYC %>%
    mutate(insurance = recode_factor(INSCOV10, .default = "Missing",
      "1" = "Any private, all ages",
      "2" = "Public only, all ages",
      "3" = "Uninsured, all ages")) %>%
    mutate(insurance_v2X = recode_factor(INSURC10, .default = "Missing",
      "1" = "<65, Any private",
      "2" = "<65, Public only",
      "3" = "<65, Uninsured",
      "4" = "65+, Medicare only",
      "5" = "65+, Medicare and private",
      "6" = "65+, Medicare and other public",
      "7" = "65+, No medicare",
      "8" = "65+, No medicare"))

# Perceived mental health
  if(year == 1996)
    FYC <- FYC %>% mutate(MNHLTH53 = MNTHLTH2, MNHLTH42 = MNTHLTH2, MNHLTH31 = MNTHLTH1)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("MNHLTH")), funs(replace(., .< 0, NA))) %>%
    mutate(mnhlth = coalesce(MNHLTH53, MNHLTH42, MNHLTH31)) %>%
    mutate(mnhlth = recode_factor(mnhlth, .default = "Missing",
      "1" = "Excellent",
      "2" = "Very good",
      "3" = "Good",
      "4" = "Fair",
      "5" = "Poor"))

FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT10F,
  data = FYC,
  nest = TRUE)

svyby(~insurance, FUN = svymean, by = ~mnhlth, design = FYCdsgn)
