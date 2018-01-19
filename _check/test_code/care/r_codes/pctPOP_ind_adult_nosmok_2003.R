# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h79.ssp');
  year <- 2003
  
  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE03X, AGE42X, AGE31X))

  FYC$ind = 1

# Adults advised to quit smoking
  if(year == 2002)
    FYC <- FYC %>% rename(ADNSMK42 = ADDSMK42)

  FYC <- FYC %>%
    mutate(
      adult_nosmok = recode_factor(ADNSMK42, .default = "Missing",
        "1" = "Told to quit",
        "2" = "Not told to quit",
        "3" = "Had no visits in the last 12 months",
        "-9" = "Not ascertained",
        "-1" = "Inapplicable"))

SAQdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~SAQWT03F,
  data = FYC,
  nest = TRUE)

svyby(~adult_nosmok, FUN = svymean, by = ~ind, design = subset(SAQdsgn, ADSMOK42==1 & CHECK53==1))
