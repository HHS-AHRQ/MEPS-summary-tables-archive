# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(.subgrps., DUPERSID, PERWT.yy.F, VARSTR, VARPSU)

# Load event files
  RX <- read.xport('.PUFdir./.RX..ssp')
  DVT <- read.xport('.PUFdir./.DV..ssp')
  IPT <- read.xport('.PUFdir./.IP..ssp')
  ERT <- read.xport('.PUFdir./.ER..ssp')
  OPT <- read.xport('.PUFdir./.OP..ssp')
  OBV <- read.xport('.PUFdir./.OB..ssp')
  HHT <- read.xport('.PUFdir./.HH..ssp')

# Define sub-levels for office-based and outpatient
  OBV <- OBV %>%
    mutate(event_v2X = recode_factor(
      SEEDOC, .default = 'Missing', '1' = 'OBD', '2' = 'OBO'))

  OPT <- OPT %>%
    mutate(event_v2X = recode_factor(
      SEEDOC, .default = 'Missing', '1' = 'OPY', '2' = 'OPZ'))
