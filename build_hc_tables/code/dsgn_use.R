# Svydesign for USE and EXP tables

FYCdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWTF,
  data = FYC,
  nest = TRUE)

EVNTdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWTF,           
  data = EVENTS,
  nest = TRUE)

# Average events per person ---------------------------------------------------
  
pers_events <- stacked_events %>%
  group_by(DUPERSID) %>%
  summarise(
    ANY = sum(XPX >= 0), EXP = sum(XPX > 0), SLF = sum(SFX > 0),
    MCR = sum(MRX > 0),  MCD = sum(MDX > 0), PTR = sum(PRX > 0),
    OTZ = sum(OZX > 0)) %>%
  ungroup
  
  n_events <- full_join(pers_events, FYCsub, by='DUPERSID') %>%
    mutate_at(vars(ANY, EXP, SLF, MCR, MCD, PTR, OTZ),
              function(x) ifelse(is.na(x), 0, x))
  
  nEVTdsgn <- svydesign(
    id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~PERWTF,
    data = n_events,
    nest = TRUE)

# Average events per person, by event type ------------------------------------
    
  # Combine stacked_events with phys./non-phys indicator (event_v2X)
  stacked_v2X <- stacked_events %>% 
    select(-event) %>%
    rename(event = event_v2X) %>%
    filter(!is.na(event), event != "Missing")
  
  # Count number of events for each person
  pers_events <- bind_rows(stacked_events, stacked_v2X) %>%
    group_by(DUPERSID, event) %>%
    summarise(
      ANY = sum(XPX >= 0), EXP = sum(XPX > 0), SLF = sum(SFX > 0),
      MCR = sum(MRX > 0),  MCD = sum(MDX > 0), PTR = sum(PRX > 0),
      OTZ = sum(OZX > 0)) %>%
    ungroup
  
  # Add filler 0's for people that have no events
  events <- c("DVT", "RX",  "OBV", "OBD", "OBO", "OPT",
              "OPY", "OPZ", "ERT", "IPT", "HHT")
  
  filler <- expand.grid(DUPERSID = FYCsub$DUPERSID, event = events)
  
  n_events <- pers_events %>% 
    full_join(filler) %>%
    full_join(FYCsub) %>% # add demographic vars
    mutate_at(vars(ANY, EXP, SLF, MCR, MCD, PTR, OTZ),
              function(x) ifelse(is.na(x), 0, x))
  
  EVdsgn <- svydesign(
    id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~PERWTF,
    data = n_events,
    nest = TRUE)

