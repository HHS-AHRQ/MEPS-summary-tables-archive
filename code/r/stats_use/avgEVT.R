event_code <- '
# Create datasets for physician / non-physician office-based / outpatient events
  OBD = OBV %>% filter(event_v2X == "OBD")
  OBO = OBV %>% filter(event_v2X == "OBO")
  OPY = OPT %>% filter(event_v2X == "OPY")
  OPZ = OPT %>% filter(event_v2X == "OPZ")

  events <- c("DVT", "RX",  "OBV", "OBD", "OBO", "OPT",
              "OPY", "OPZ", "ERT", "IPT", "HHT")

# Run for each event dataset
  results <- list()
  for(ev in events) {
    key <- ev
    df <- get(key) %>%
      rm_evnt_key() %>%
      add_total_sops() %>%
      mutate(PR.yy.X = PV.yy.X + TR.yy.X,
             OZ.yy.X = OF.yy.X + SL.yy.X + OT.yy.X + OR.yy.X + OU.yy.X + WC.yy.X + VA.yy.X)

    pers_events <- df %>%
      group_by(DUPERSID) %>%
      summarise(ANY = sum(XP.yy.X >= 0),
                EXP = sum(XP.yy.X > 0),
                SLF = sum(SF.yy.X > 0),
                MCR = sum(MR.yy.X > 0),
                MCD = sum(MD.yy.X > 0),
                PTR = sum(PR.yy.X > 0),
                OTZ = sum(OZ.yy.X > 0))

    n_events <- full_join(pers_events,FYCsub,by="DUPERSID") %>%
      mutate_at(vars(ANY, EXP, SLF, MCR, MCD, PTR, OTZ),
                function(x) ifelse(is.na(x),0,x))

    EVdsgn <- svydesign(
      id = ~VARPSU,
      strata = ~VARSTR,
      weights = ~PERWT.yy.F,
      data = n_events,
      nest = TRUE)

    results[[key]] <- svyby(~.sop_formula., by = ~.by., FUN = svymean, design = EVdsgn)
  }
  print(results)
'

list(
  demo  = 'svyby(~ANY, FUN=svymean, by = ~.by., design = nEVTdsgn)',
  sop   = 'svyby(~EXP + SLF + MCR + MCD + PTR + OTZ, FUN=svymean, by = ~.by., design = nEVTdsgn)',
  event = event_code %>% rsub(sop_formula = "ANY"),
  event_sop = event_code %>% rsub(sop_formula = "EXP + SLF + MCR + MCD + PTR + OTZ")
)
