
# Load event files
  RX  <- read_MEPS(year = year, type = "RX") %>% rename(EVNTIDX = LINKIDX)
  DVT <- read_MEPS(year = year, type = "DV")
  IPT <- read_MEPS(year = year, type = "IP")
  ERT <- read_MEPS(year = year, type = "ER")
  OPT <- read_MEPS(year = year, type = "OP")
  OBV <- read_MEPS(year = year, type = "OB")
  HHT <- read_MEPS(year = year, type = "HH")

# Define sub-levels for office-based and outpatient
  
  if(year < 2018) {
    OBV$seedoc_var = OBV$SEEDOC    
    OPT$seedoc_var = OPT$SEEDOC
  } else{
    OBV$seedoc_var = OBV$SEEDOC_M18    
    OPT$seedoc_var = OPT$SEEDOC_M18
  }
  
  OBV <- OBV %>%
    mutate(event_v2X = recode_factor(
      seedoc_var, 
      .default = 'Missing', .missing = "Missing", 
      '1' = 'OBD', '2' = 'OBO'))
  
  OPT <- OPT %>%
    mutate(event_v2X = recode_factor(
      seedoc_var, 
      .default = 'Missing', .missing = "Missing", 
      '1' = 'OPY', '2' = 'OPZ'))

# Stack events
  stacked_events <- stack_events(
    RX, DVT, IPT, ERT, OPT, OBV, HHT,
    keep.vars = c('seedoc_var','event_v2X'))
  
# Remove 'yr' from colnames
  colnames(stacked_events) <- colnames(stacked_events) %>% gsub(yr,"",.)
  
  stacked_events <- stacked_events %>%
    mutate(event = data,
           PRX = PVX + TRX,
           OZX = OFX + SLX + OTX + ORX + OUX + WCX + VAX) %>%
    select(DUPERSID, event, event_v2X, seedoc_var,
           XPX, SFX, MRX, MDX, PRX, OZX)
  
# Add demographic and survey vars from FYC file
  EVENTS <- stacked_events %>% full_join(FYCsub, by = 'DUPERSID')
