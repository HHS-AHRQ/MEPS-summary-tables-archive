
library(MEPS)
library(survey)

options(survey.lonely.psu="adjust")

# Load FYC file
year <- 2017
FYC <- read_MEPS(year = year, type = "FYC", dir = "C:/MEPS")


FYC <- FYC %>%
  mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
  mutate(AGELAST = coalesce(AGE17X, AGE42X, AGE31X))

FYC$ind = 1  

# Marital status
if(year == 1996){
  FYC <- FYC %>%
    mutate(MARRY42X = ifelse(MARRY2X <= 6, MARRY2X, MARRY2X-6),
           MARRY31X = ifelse(MARRY1X <= 6, MARRY1X, MARRY1X-6))
}

FYC <- FYC %>%
  mutate_at(vars(starts_with("MARRY")), funs(replace(., .< 0, NA))) %>%
  mutate(married = coalesce(MARRY17X, MARRY42X, MARRY31X)) %>%
  mutate(married = recode_factor(married, .default = "Missing", .missing = "Missing", 
                                 "1" = "Married",
                                 "2" = "Widowed",
                                 "3" = "Divorced",
                                 "4" = "Separated",
                                 "5" = "Never married",
                                 "6" = "Inapplicable (age < 16)"))

# Add aggregate event variables
FYC <- FYC %>% mutate(
  HHTEXP17 = HHAEXP17 + HHNEXP17, # Home Health Agency + Independent providers
  ERTEXP17 = ERFEXP17 + ERDEXP17, # Doctor + Facility Expenses for OP, ER, IP events
  IPTEXP17 = IPFEXP17 + IPDEXP17,
  OPTEXP17 = OPFEXP17 + OPDEXP17, # All Outpatient
  OPYEXP17 = OPVEXP17 + OPSEXP17, # Outpatient - Physician only
  OMAEXP17 = VISEXP17 + OTHEXP17) # Other medical equipment and services

FYC <- FYC %>% mutate(
  TOTUSE17 = ((DVTOT17 > 0) + (RXTOT17 > 0) + (OBTOTV17 > 0) +
                (OPTOTV17 > 0) + (ERTOT17 > 0) + (IPDIS17 > 0) +
                (HHTOTD17 > 0) + (OMAEXP17 > 0))
)


FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT17F,
  data = FYC,
  nest = TRUE)

# p over event types
events <- c("TOT", "DVT", "RX",  "OBV", "OBD",
            "OPT", "OPY", "ERT", "IPT", "HHT", "OMA")


# results <- list()
# for(ev in events) {
#   key <- paste0(ev, "EXP", "17")
#   formula <- as.formula(sprintf("~%s", key))
#   results[[key]] <- svyby(formula, FUN = svyquantile, by = ~married, design = subset(FYCdsgn, FYC[[key]] > 0), quantiles=c(0.5), ci=T, method="constant")
# }


for(itype in interval.types) {
  for(tietype in ties) {
    for(method in methods) {
      
      
    }
  }
}


require(devtools)
#install_version("survey", version = "3.34", repos = "http://cran.us.r-project.org")
update.packages("survey")
library(survey)

# Original code - consistent using version 3.34
svyby(~OPYEXP17, FUN = svyquantile, 
      by = ~married, 
      design = subset(FYCdsgn, OPYEXP17 > 0), 
      quantiles=c(0.5), ci = T, 
      method = "constant")

svyby(~OPTEXP17, FUN = svyquantile, by = ~married, design = subset(FYCdsgn, OPTEXP17 > 0), 
      quantiles=c(0.5), ci = T, 
      method = "constant")




svyby(~OPYEXP17, FUN = svyquantile, by = ~married, design = subset(FYCdsgn, OPYEXP17 > 0), 
      quantiles=c(0.5), 
      interval.type = "Wald",
      ci=T, method="constant")

svyby(~OPYEXP17, FUN = svyquantile, by = ~married, design = subset(FYCdsgn, OPYEXP17 > 0), 
      quantiles=c(0.5),
      interval.type = "betaWald",
      ci=T)



print(results)







