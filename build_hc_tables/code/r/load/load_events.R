# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(.subgrps., DUPERSID, PERWT.yy.F, VARSTR, VARPSU)

# Load event files
  RX <- read_sas('.PUFdir./.RX..sas7bdat')
  DVT <- read_sas('.PUFdir./.DV..sas7bdat')
  IPT <- read_sas('.PUFdir./.IP..sas7bdat')
  ERT <- read_sas('.PUFdir./.ER..sas7bdat')
  OPT <- read_sas('.PUFdir./.OP..sas7bdat')
  OBV <- read_sas('.PUFdir./.OB..sas7bdat')
  HHT <- read_sas('.PUFdir./.HH..sas7bdat')

# Define sub-levels for office-based and outpatient
#  To compute estimates for these sub-events, replace 'event' with 'event_v2X'
#  in the 'svyby' statement below, when applicable
  OBV <- OBV %>%
    mutate(event_v2X = recode_factor(
      SEEDOC, .default = 'Missing', .missing = "Missing", '1' = 'OBD', '2' = 'OBO'))

  OPT <- OPT %>%
    mutate(event_v2X = recode_factor(
      SEEDOC, .default = 'Missing', .missing = "Missing", '1' = 'OPY', '2' = 'OPZ'))
