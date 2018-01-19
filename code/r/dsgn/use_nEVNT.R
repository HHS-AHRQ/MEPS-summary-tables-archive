pers_events <- stacked_events %>%
  group_by(DUPERSID) %>%
  summarise(ANY = sum(XP.yy.X >= 0),
            EXP = sum(XP.yy.X > 0),
            SLF = sum(SF.yy.X > 0),
            MCR = sum(MR.yy.X > 0),
            MCD = sum(MD.yy.X > 0),
            PTR = sum(PR.yy.X > 0),
            OTZ = sum(OZ.yy.X > 0)) %>%
  ungroup

n_events <- full_join(pers_events,FYCsub,by='DUPERSID') %>%
  mutate_at(vars(ANY,EXP,SLF,MCR,MCD,PTR,OTZ),
            function(x) ifelse(is.na(x),0,x))

nEVTdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~PERWT.yy.F,
  data = n_events,
  nest = TRUE)
