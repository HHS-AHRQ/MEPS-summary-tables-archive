# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read_sas('C:/MEPS/.FYC..sas7bdat');
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
    race = recode_factor(race, .default = "Missing", .missing = "Missing", 
      "1" = "Hispanic",
      "2" = "White",
      "3" = "Black",
      "4" = "Amer. Indian, AK Native, or mult. races",
      "5" = "Asian, Hawaiian, or Pacific Islander",
      "9" = "White and other"))

FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT.yy.F,
  data = FYC,
  nest = TRUE)

results <- svyby(~afford_ANY + insure_ANY + other_ANY, FUN = svytotal, by = ~race, design = subset(FYCdsgn, ACCELI42==1 & delay_ANY==1))
print(results)
