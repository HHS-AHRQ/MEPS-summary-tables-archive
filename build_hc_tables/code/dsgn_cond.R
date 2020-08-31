# Sum by person, condition, across event
  all_pers <- all_events %>%
    group_by(DUPERSID, Condition, count) %>%
    mutate_at(vars(SFX, PRX, MRX, MDX, OZX, XPX), sum) %>% 
    select(
      one_of(demo_grps), 
      SFX, PRX, MRX, MDX, OZX, XPX,
      ind, count, VARSTR, VARPSU, PERWTF) %>%
    ungroup %>% distinct
  
  PERSdsgn <- svydesign(
    id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~PERWTF,
    data = all_pers,
    nest = TRUE)

# Sum by person, condition, event;
  all_persev <- all_events %>%
    group_by(ind, DUPERSID, VARSTR, VARPSU, PERWTF, Condition, event, count) %>%
    summarize_at(vars(SFX, PRX, MRX, MDX, OZX, XPX), sum) %>% ungroup
  
  PERSevnt <- svydesign(
    id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~PERWTF,
    data = all_persev,
    nest = TRUE)
  
  EVNTdsgn <- svydesign(
    id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~PERWTF,           
    data = all_events,
    nest = TRUE) 
  
  n_pers <- all_pers %>%
    gather(sop, XP, SFX, PRX, MRX, MDX, OZX, XPX) 
  
  ndsgn <- svydesign(
    id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~PERWTF,
    data = n_pers,
    nest = TRUE)