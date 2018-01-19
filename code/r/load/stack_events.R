# Stack events
  stacked_events <- stack_events(RX, DVT, IPT, ERT, OPT, OBV, HHT,
    keep.vars = c('SEEDOC','event_v2X'))

  stacked_events <- stacked_events %>%
    mutate(event = data,
           PR.yy.X = PV.yy.X + TR.yy.X,
           OZ.yy.X = OF.yy.X + SL.yy.X + OT.yy.X + OR.yy.X + OU.yy.X + WC.yy.X + VA.yy.X) %>%
    select(DUPERSID, event, event_v2X, SEEDOC,
      XP.yy.X, SF.yy.X, MR.yy.X, MD.yy.X, PR.yy.X, OZ.yy.X)
