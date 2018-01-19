# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h147.ssp');
  year <- 2011

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU11, VARSTR=VARSTR11)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT11F = WTDPER11)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE11X, AGE42X, AGE31X))

  FYC$ind = 1  

# Add aggregate sources of payment for all event types
  evt <- c("TOT","RX","DVT","OBV","OBD","OBO",
           "OPF","OPD","OPV","OPS","OPO","OPP",
           "ERF","ERD","IPF","IPD","HHA","HHN",
           "VIS","OTH")

  if(year <= 1999)
    FYC[,sprintf("%sTRI11",evt)] <- FYC[,sprintf("%sCHM11", evt)]

  FYC[,sprintf("%sPTR11",evt)] <-
    FYC[,sprintf("%sPRV11",evt)]+
    FYC[,sprintf("%sTRI11",evt)]

  FYC[,sprintf("%sOTH11",evt)] <-
    FYC[,sprintf("%sOFD11",evt)]+
    FYC[,sprintf("%sSTL11",evt)]+
    FYC[,sprintf("%sOPR11",evt)]+
    FYC[,sprintf("%sOPU11",evt)]+
    FYC[,sprintf("%sOSR11",evt)]

  FYC[,sprintf("%sOTZ11",evt)] <-
    FYC[,sprintf("%sOTH11",evt)]+
    FYC[,sprintf("%sVA11",evt)]+
    FYC[,sprintf("%sWCP11",evt)]

# Add aggregate event variables for all sources of payment
  sop <- c("EXP","SLF","PTR","MCR","MCD","OTZ")

  FYC[,sprintf("OMA%s11",sop)] = FYC[,sprintf("VIS%s11",sop)]+FYC[,sprintf("OTH%s11",sop)]
  FYC[,sprintf("HHT%s11",sop)] = FYC[,sprintf("HHA%s11",sop)]+FYC[,sprintf("HHN%s11",sop)]
  FYC[,sprintf("ERT%s11",sop)] = FYC[,sprintf("ERF%s11",sop)]+FYC[,sprintf("ERD%s11",sop)]
  FYC[,sprintf("IPT%s11",sop)] = FYC[,sprintf("IPF%s11",sop)]+FYC[,sprintf("IPD%s11",sop)]

  FYC[,sprintf("OPT%s11",sop)] = FYC[,sprintf("OPF%s11",sop)]+FYC[,sprintf("OPD%s11",sop)]
  FYC[,sprintf("OPY%s11",sop)] = FYC[,sprintf("OPV%s11",sop)]+FYC[,sprintf("OPS%s11",sop)]
  FYC[,sprintf("OPZ%s11",sop)] = FYC[,sprintf("OPO%s11",sop)]+FYC[,sprintf("OPP%s11",sop)]

FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT11F,
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
      formula <- as.formula(sprintf("~%s11", key))
      results[[key]] <- svyby(formula, FUN = svytotal, by = ~ind, design = FYCdsgn)
    }
  }
  print(results)
