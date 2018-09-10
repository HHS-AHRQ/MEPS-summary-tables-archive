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

# Add aggregate sources of payment for all event types
  evt <- c("TOT","RX","DVT","OBV","OBD","OBO",
           "OPF","OPD","OPV","OPS","OPO","OPP",
           "ERF","ERD","IPF","IPD","HHA","HHN",
           "VIS","OTH")

  if(year <= 1999)
    FYC[,sprintf("%sTRI.yy.",evt)] <- FYC[,sprintf("%sCHM.yy.", evt)]

  FYC[,sprintf("%sPTR.yy.",evt)] <-
    FYC[,sprintf("%sPRV.yy.",evt)]+
    FYC[,sprintf("%sTRI.yy.",evt)]

  FYC[,sprintf("%sOTH.yy.",evt)] <-
    FYC[,sprintf("%sOFD.yy.",evt)]+
    FYC[,sprintf("%sSTL.yy.",evt)]+
    FYC[,sprintf("%sOPR.yy.",evt)]+
    FYC[,sprintf("%sOPU.yy.",evt)]+
    FYC[,sprintf("%sOSR.yy.",evt)]

  FYC[,sprintf("%sOTZ.yy.",evt)] <-
    FYC[,sprintf("%sOTH.yy.",evt)]+
    FYC[,sprintf("%sVA.yy.",evt)]+
    FYC[,sprintf("%sWCP.yy.",evt)]

# Add aggregate event variables for all sources of payment
  sop <- c("EXP","SLF","PTR","MCR","MCD","OTZ")

  FYC[,sprintf("OMA%s.yy.",sop)] = FYC[,sprintf("VIS%s.yy.",sop)]+FYC[,sprintf("OTH%s.yy.",sop)]
  FYC[,sprintf("HHT%s.yy.",sop)] = FYC[,sprintf("HHA%s.yy.",sop)]+FYC[,sprintf("HHN%s.yy.",sop)]
  FYC[,sprintf("ERT%s.yy.",sop)] = FYC[,sprintf("ERF%s.yy.",sop)]+FYC[,sprintf("ERD%s.yy.",sop)]
  FYC[,sprintf("IPT%s.yy.",sop)] = FYC[,sprintf("IPF%s.yy.",sop)]+FYC[,sprintf("IPD%s.yy.",sop)]

  FYC[,sprintf("OPT%s.yy.",sop)] = FYC[,sprintf("OPF%s.yy.",sop)]+FYC[,sprintf("OPD%s.yy.",sop)]
  FYC[,sprintf("OPY%s.yy.",sop)] = FYC[,sprintf("OPV%s.yy.",sop)]+FYC[,sprintf("OPS%s.yy.",sop)]
  FYC[,sprintf("OPZ%s.yy.",sop)] = FYC[,sprintf("OPO%s.yy.",sop)]+FYC[,sprintf("OPP%s.yy.",sop)]

FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT.yy.F,
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
      formula <- as.formula(sprintf("~(%s.yy. > 0)", key))
      results[[key]] <- svyby(formula, FUN = svytotal, by = ~ind, design = FYCdsgn)
    }
  }

print(results)
