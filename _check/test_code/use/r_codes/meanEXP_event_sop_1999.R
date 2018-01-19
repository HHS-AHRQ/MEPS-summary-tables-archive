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

# Add aggregate sources of payment for all event types
  evt <- c("TOT","RX","DVT","OBV","OBD","OBO",
           "OPF","OPD","OPV","OPS","OPO","OPP",
           "ERF","ERD","IPF","IPD","HHA","HHN",
           "VIS","OTH")

  if(year <= 1999)
    FYC[,sprintf("%sTRI99",evt)] <- FYC[,sprintf("%sCHM99", evt)]

  FYC[,sprintf("%sPTR99",evt)] <-
    FYC[,sprintf("%sPRV99",evt)]+
    FYC[,sprintf("%sTRI99",evt)]

  FYC[,sprintf("%sOTH99",evt)] <-
    FYC[,sprintf("%sOFD99",evt)]+
    FYC[,sprintf("%sSTL99",evt)]+
    FYC[,sprintf("%sOPR99",evt)]+
    FYC[,sprintf("%sOPU99",evt)]+
    FYC[,sprintf("%sOSR99",evt)]

  FYC[,sprintf("%sOTZ99",evt)] <-
    FYC[,sprintf("%sOTH99",evt)]+
    FYC[,sprintf("%sVA99",evt)]+
    FYC[,sprintf("%sWCP99",evt)]

# Add aggregate event variables for all sources of payment
  sop <- c("EXP","SLF","PTR","MCR","MCD","OTZ")

  FYC[,sprintf("OMA%s99",sop)] = FYC[,sprintf("VIS%s99",sop)]+FYC[,sprintf("OTH%s99",sop)]
  FYC[,sprintf("HHT%s99",sop)] = FYC[,sprintf("HHA%s99",sop)]+FYC[,sprintf("HHN%s99",sop)]
  FYC[,sprintf("ERT%s99",sop)] = FYC[,sprintf("ERF%s99",sop)]+FYC[,sprintf("ERD%s99",sop)]
  FYC[,sprintf("IPT%s99",sop)] = FYC[,sprintf("IPF%s99",sop)]+FYC[,sprintf("IPD%s99",sop)]

  FYC[,sprintf("OPT%s99",sop)] = FYC[,sprintf("OPF%s99",sop)]+FYC[,sprintf("OPD%s99",sop)]
  FYC[,sprintf("OPY%s99",sop)] = FYC[,sprintf("OPV%s99",sop)]+FYC[,sprintf("OPS%s99",sop)]
  FYC[,sprintf("OPZ%s99",sop)] = FYC[,sprintf("OPO%s99",sop)]+FYC[,sprintf("OPP%s99",sop)]

FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT99F,
  data = FYC,
  nest = TRUE)

# Loop over events, sops
  events <- c("TOT", "DVT", "RX",  "OBV", "OBD", "OBO",
              "OPT", "OPY", "OPZ", "ERT", "IPT", "HHT", "OMA")

  sops <- c("EXP", "SLF", "PTR", "MCR", "MCD", "OTZ")

  results <- list()
  for(ev in events) {
    for(sp in sops) {
      key <- paste0(ev, sp, "99")
      formula <- as.formula(sprintf("~%s", key))
      results[[key]] <- svyby(formula, FUN = svymean, by = ~ind, design = subset(FYCdsgn, FYC[[key]] > 0))
    }
  }
  print(results)
