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

# Add aggregate sources of payment
  if(year <= 1999)
    FYC <- FYC %>% mutate(TOTTRI.yy. = TOTCHM.yy.)

  FYC <- FYC %>% mutate(
    TOTOTH.yy. = TOTOFD.yy. + TOTSTL.yy. + TOTOPR.yy. + TOTOPU.yy. + TOTOSR.yy.,
    TOTOTZ.yy. = TOTOTH.yy. + TOTWCP.yy. + TOTVA.yy.,
    TOTPTR.yy. = TOTPRV.yy. + TOTTRI.yy.)

# Sex
  FYC <- FYC %>%
    mutate(sex = recode_factor(SEX, .default = "Missing", .missing = "Missing", 
      "1" = "Male",
      "2" = "Female"))

FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT.yy.F,
  data = FYC,
  nest = TRUE)

# Loop over sources of payment
  sops <- c("EXP", "SLF", "PTR", "MCR", "MCD", "OTZ")
  results <- list()

  for(sp in sops) {
    key <- paste0("TOT", sp, ".yy.")
    formula <- as.formula(sprintf("~%s", key))
    results[[key]] <- svyby(formula, FUN = svyquantile, by = ~sex, design = subset(FYCdsgn, FYC[[key]] > 0), quantiles=c(0.5), ci=T, method="constant")
  }

print(results)
