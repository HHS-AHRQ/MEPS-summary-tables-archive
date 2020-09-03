
# Load conditions PUF file
  cond_puf <- read_MEPS(year = year, type = "Conditions") %>%
    select(DUPERSID, CONDIDX, starts_with("CC"))


# Merge condition cdes
  
ccs_url <- "https://raw.githubusercontent.com/HHS-AHRQ/MEPS/master/Quick_Reference_Guides/meps_ccs_conditions.csv"
ccsr_url <- "https://raw.githubusercontent.com/HHS-AHRQ/MEPS/master/Quick_Reference_Guides/meps_ccsr_conditions.csv"


  if(year < 2018) {
    condition_codes <- read_csv(ccs_url) %>%
      setNames(c("CCS", "CCS_desc", "Condition"))
    
    cond <- cond_puf %>% mutate(CCS = CCCODEX) %>%
      mutate(CCS_Codes = as.numeric(as.character(CCS))) %>%
      left_join(condition_codes, by = "CCS_Codes")
    
  } else {
    
    condition_codes <- read_csv(ccsr_url) %>% 
      setNames(c("CCSR", "CCSR_desc", "Condition"))
    
    # Convert multiple CCSRs to separate lines 
    cond <- cond_puf %>% 
      gather(CCSRnum, CCSR, CCSR1X:CCSR3X) %>% 
      filter(CCSR != "") %>%
      left_join(condition_codes)
  }
  
# Load event files
  RX  <- read_MEPS(year = year, type = "RX") %>% rename(EVNTIDX = LINKIDX)
  IPT <- read_MEPS(year = year, type = "IP")
  ERT <- read_MEPS(year = year, type = "ER")
  OPT <- read_MEPS(year = year, type = "OP")
  OBV <- read_MEPS(year = year, type = "OB")
  HHT <- read_MEPS(year = year, type = "HH")
  
# Load event-condition linking file
  clink1 <- read_MEPS(year = year, type = "CLNK") %>%
    select(DUPERSID, CONDIDX, EVNTIDX)

# Stack events (condition data not collected for DN and OM events)
  stacked_events <- stack_events(RX, IPT, ERT, OPT, OBV, HHT)

# Remove 'yr' from colnames
  colnames(stacked_events) <- colnames(stacked_events) %>% gsub(yr,"",.)
  
  stacked_events <- stacked_events %>%
    mutate(event = data,
           PRX = PVX + TRX,
           OZX = OFX + SLX + OTX + ORX + OUX + WCX + VAX) %>%
    select(DUPERSID, event, EVNTIDX,
           XPX, SFX, MRX, MDX, PRX, OZX)

  
# Merge link file
  cond <- cond %>%
    full_join(clink1, by = c("DUPERSID", "CONDIDX")) %>%
    distinct(DUPERSID, EVNTIDX, Condition, .keep_all=T)
  
# Merge events with conditions-link file and FYCsub
  all_events <- full_join(stacked_events, cond, by = c("DUPERSID", "EVNTIDX")) %>%
    filter(!is.na(Condition), XPX >= 0) %>%
    mutate(count = 1) %>%
    full_join(FYCsub, by = "DUPERSID")
