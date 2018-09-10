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
  
  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE.yy.X, AGE42X, AGE31X))

  FYC$ind = 1

# Reason for difficulty receiving needed care
  FYC <- FYC %>%
    mutate(
      delay_MD  = (MDUNAB42 == 1 | MDDLAY42==1)*1,
      delay_DN  = (DNUNAB42 == 1 | DNDLAY42==1)*1,
      delay_PM  = (PMUNAB42 == 1 | PMDLAY42==1)*1,

      afford_MD = (MDDLRS42 == 1 | MDUNRS42 == 1)*1,
      afford_DN = (DNDLRS42 == 1 | DNUNRS42 == 1)*1,
      afford_PM = (PMDLRS42 == 1 | PMUNRS42 == 1)*1,

      insure_MD = (MDDLRS42 %in% c(2,3) | MDUNRS42 %in% c(2,3))*1,
      insure_DN = (DNDLRS42 %in% c(2,3) | DNUNRS42 %in% c(2,3))*1,
      insure_PM = (PMDLRS42 %in% c(2,3) | PMUNRS42 %in% c(2,3))*1,

      other_MD  = (MDDLRS42 > 3 | MDUNRS42 > 3)*1,
      other_DN  = (DNDLRS42 > 3 | DNUNRS42 > 3)*1,
      other_PM  = (PMDLRS42 > 3 | PMUNRS42 > 3)*1,

      delay_ANY  = (delay_MD  | delay_DN  | delay_PM)*1,
      afford_ANY = (afford_MD | afford_DN | afford_PM)*1,
      insure_ANY = (insure_MD | insure_DN | insure_PM)*1,
      other_ANY  = (other_MD  | other_DN  | other_PM)*1)

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

FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT.yy.F,
  data = FYC,
  nest = TRUE)

results <- svyby(~afford_ANY + insure_ANY + other_ANY, FUN = svymean, by = ~insurance, design = subset(FYCdsgn, ACCELI42==1 & delay_ANY==1))
print(results)
