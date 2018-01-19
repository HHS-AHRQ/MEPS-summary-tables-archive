# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h181.ssp');
  year <- 2015

  if(year <= 2001) FYC <- FYC %>% mutate(VARPSU = VARPSU15, VARSTR=VARSTR15)
  if(year <= 1998) FYC <- FYC %>% rename(PERWT15F = WTDPER15)
  if(year == 1996) FYC <- FYC %>% mutate(AGE42X = AGE2X, AGE31X = AGE1X)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE15X, AGE42X, AGE31X))

  FYC$ind = 1  

# Add aggregate sources of payment for all event types
  evt <- c("TOT","RX","DVT","OBV","OBD","OBO",
           "OPF","OPD","OPV","OPS","OPO","OPP",
           "ERF","ERD","IPF","IPD","HHA","HHN",
           "VIS","OTH")

  if(year <= 1999)
    FYC[,sprintf("%sTRI15",evt)] <- FYC[,sprintf("%sCHM15", evt)]

  FYC[,sprintf("%sPTR15",evt)] <-
    FYC[,sprintf("%sPRV15",evt)]+
    FYC[,sprintf("%sTRI15",evt)]

  FYC[,sprintf("%sOTH15",evt)] <-
    FYC[,sprintf("%sOFD15",evt)]+
    FYC[,sprintf("%sSTL15",evt)]+
    FYC[,sprintf("%sOPR15",evt)]+
    FYC[,sprintf("%sOPU15",evt)]+
    FYC[,sprintf("%sOSR15",evt)]

  FYC[,sprintf("%sOTZ15",evt)] <-
    FYC[,sprintf("%sOTH15",evt)]+
    FYC[,sprintf("%sVA15",evt)]+
    FYC[,sprintf("%sWCP15",evt)]

# Add aggregate event variables for all sources of payment
  sop <- c("EXP","SLF","PTR","MCR","MCD","OTZ")

  FYC[,sprintf("OMA%s15",sop)] = FYC[,sprintf("VIS%s15",sop)]+FYC[,sprintf("OTH%s15",sop)]
  FYC[,sprintf("HHT%s15",sop)] = FYC[,sprintf("HHA%s15",sop)]+FYC[,sprintf("HHN%s15",sop)]
  FYC[,sprintf("ERT%s15",sop)] = FYC[,sprintf("ERF%s15",sop)]+FYC[,sprintf("ERD%s15",sop)]
  FYC[,sprintf("IPT%s15",sop)] = FYC[,sprintf("IPF%s15",sop)]+FYC[,sprintf("IPD%s15",sop)]

  FYC[,sprintf("OPT%s15",sop)] = FYC[,sprintf("OPF%s15",sop)]+FYC[,sprintf("OPD%s15",sop)]
  FYC[,sprintf("OPY%s15",sop)] = FYC[,sprintf("OPV%s15",sop)]+FYC[,sprintf("OPS%s15",sop)]
  FYC[,sprintf("OPZ%s15",sop)] = FYC[,sprintf("OPO%s15",sop)]+FYC[,sprintf("OPP%s15",sop)]

FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT15F,
  data = FYC,
  nest = TRUE)

# Loop over events, sops
  events <- c("TOT", "DVT", "RX",  "OBV", "OBD", "OBO",
              "OPT", "OPY", "OPZ", "ERT", "IPT", "HHT", "OMA")

  sops <- c("EXP", "SLF", "PTR", "MCR", "MCD", "OTZ")

  results <- list()
  for(ev in events) {
    for(sp in sops) {
      key <- paste0(ev, sp, "15")
      formula <- as.formula(sprintf("~%s", key))
      results[[key]] <- svyby(formula, FUN = svyquantile, by = ~ind, design = subset(FYCdsgn, FYC[[key]] > 0), quantiles=c(0.5), ci=T, method="constant")
    }
  }
  print(results)
