# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h12.ssp');
  year <- 1996

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU96, VARSTR=VARSTR96)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT96F = WTDPER96)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE96X, AGE42X, AGE31X))

  FYC$ind = 1  

# Add aggregate sources of payment for all event types
  evt <- c("TOT","RX","DVT","OBV","OBD","OBO",
           "OPF","OPD","OPV","OPS","OPO","OPP",
           "ERF","ERD","IPF","IPD","HHA","HHN",
           "VIS","OTH")

  if(year <= 1999)
    FYC[,sprintf("%sTRI96",evt)] <- FYC[,sprintf("%sCHM96", evt)]

  FYC[,sprintf("%sPTR96",evt)] <-
    FYC[,sprintf("%sPRV96",evt)]+
    FYC[,sprintf("%sTRI96",evt)]

  FYC[,sprintf("%sOTH96",evt)] <-
    FYC[,sprintf("%sOFD96",evt)]+
    FYC[,sprintf("%sSTL96",evt)]+
    FYC[,sprintf("%sOPR96",evt)]+
    FYC[,sprintf("%sOPU96",evt)]+
    FYC[,sprintf("%sOSR96",evt)]

  FYC[,sprintf("%sOTZ96",evt)] <-
    FYC[,sprintf("%sOTH96",evt)]+
    FYC[,sprintf("%sVA96",evt)]+
    FYC[,sprintf("%sWCP96",evt)]

# Add aggregate event variables for all sources of payment
  sop <- c("EXP","SLF","PTR","MCR","MCD","OTZ")

  FYC[,sprintf("OMA%s96",sop)] = FYC[,sprintf("VIS%s96",sop)]+FYC[,sprintf("OTH%s96",sop)]
  FYC[,sprintf("HHT%s96",sop)] = FYC[,sprintf("HHA%s96",sop)]+FYC[,sprintf("HHN%s96",sop)]
  FYC[,sprintf("ERT%s96",sop)] = FYC[,sprintf("ERF%s96",sop)]+FYC[,sprintf("ERD%s96",sop)]
  FYC[,sprintf("IPT%s96",sop)] = FYC[,sprintf("IPF%s96",sop)]+FYC[,sprintf("IPD%s96",sop)]

  FYC[,sprintf("OPT%s96",sop)] = FYC[,sprintf("OPF%s96",sop)]+FYC[,sprintf("OPD%s96",sop)]
  FYC[,sprintf("OPY%s96",sop)] = FYC[,sprintf("OPV%s96",sop)]+FYC[,sprintf("OPS%s96",sop)]
  FYC[,sprintf("OPZ%s96",sop)] = FYC[,sprintf("OPO%s96",sop)]+FYC[,sprintf("OPP%s96",sop)]

FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT96F,
  data = FYC,
  nest = TRUE)

# Loop over events, sops
  events <- c("TOT", "DVT", "RX",  "OBV", "OBD", "OBO",
              "OPT", "OPY", "OPZ", "ERT", "IPT", "HHT", "OMA")

  sops <- c("EXP", "SLF", "PTR", "MCR", "MCD", "OTZ")

  results <- list()
  for(ev in events) {
    for(sp in sops) {
      key <- paste0(ev, sp)
      formula <- as.formula(sprintf("~(%s96 > 0)", key))
      results[[key]] <- svyby(formula, FUN = svymean, by = ~ind, design = FYCdsgn)
    }
  }
  print(results)
