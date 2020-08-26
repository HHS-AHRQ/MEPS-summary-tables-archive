# Keep only needed variables from FYC
  FYCsub <- FYC %>% select(.subgrps., DUPERSID, PERWT.yy.F, VARSTR, VARPSU)

# Load event files
  RX <- read_sas('.PUFdir./.RX..sas7bdat') %>% rename(EVNTIDX = LINKIDX)
  IPT <- read_sas('.PUFdir./.IP..sas7bdat')
  ERT <- read_sas('.PUFdir./.ER..sas7bdat')
  OPT <- read_sas('.PUFdir./.OP..sas7bdat')
  OBV <- read_sas('.PUFdir./.OB..sas7bdat')
  HHT <- read_sas('.PUFdir./.HH..sas7bdat')

# Stack events (condition data not collected for dental visits and other medical expenses)
  stacked_events <- stack_events(RX, IPT, ERT, OPT, OBV, HHT)

  stacked_events <- stacked_events %>%
    mutate(event = data,
           PR.yy.X = PV.yy.X + TR.yy.X,
           OZ.yy.X = OF.yy.X + SL.yy.X + OT.yy.X + OR.yy.X + OU.yy.X + WC.yy.X + VA.yy.X) %>%
    select(DUPERSID, event, EVNTIDX,
           XP.yy.X, SF.yy.X, MR.yy.X, MD.yy.X, PR.yy.X, OZ.yy.X)

# Read in event-condition linking file
  clink1 = read_sas('.PUFdir./.CLNK..sas7bdat') %>%
    select(DUPERSID,CONDIDX,EVNTIDX)

# Read in conditions file and merge with condition_codes, link file
  cond <- read_sas('.PUFdir./.Conditions..sas7bdat') %>%
    select(DUPERSID, CONDIDX, CCCODEX) %>%
    mutate(CCS_Codes = as.numeric(as.character(CCCODEX))) %>%
    left_join(condition_codes, by = "CCS_Codes") %>%
    full_join(clink1, by = c("DUPERSID", "CONDIDX")) %>%
    distinct(DUPERSID, EVNTIDX, Condition, .keep_all=T)

# Merge events with conditions-link file and FYCsub
  all_events <- full_join(stacked_events, cond, by=c("DUPERSID","EVNTIDX")) %>%
    filter(!is.na(Condition),XP.yy.X >= 0) %>%
    mutate(count = 1) %>%
    full_join(FYCsub, by = "DUPERSID")
