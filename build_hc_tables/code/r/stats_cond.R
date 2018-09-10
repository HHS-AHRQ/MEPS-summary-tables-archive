list(
  totPOP = list(
    demo  = 'results <- svyby(~count, by = ~Condition + .by., FUN = svytotal, design = PERSdsgn)',
    event = 'results <- svyby(~count, by = ~Condition + event, FUN = svytotal, design = PERSevnt)',
    sop   = 'results <- svyby(~(XP.yy.X > 0) + (SF.yy.X > 0) + (MR.yy.X > 0) + (MD.yy.X > 0) + (PR.yy.X > 0) + (OZ.yy.X > 0),\n by = ~Condition, FUN = svytotal, design = PERSdsgn)'
  ),
  totEXP = list(
    demo  = 'results <- svyby(~XP.yy.X, by = ~Condition + .by., FUN = svytotal, design = EVNTdsgn)',
    event = 'results <- svyby(~XP.yy.X, by = ~Condition + event, FUN = svytotal, design = PERSevnt)',
    sop   = 'results <- svyby(~XP.yy.X + SF.yy.X + MR.yy.X + MD.yy.X + PR.yy.X + OZ.yy.X, by = ~Condition, FUN = svytotal, design = EVNTdsgn)'
  ),
  totEVT = list(
    demo  = 'results <- svyby(~count, by = ~Condition + .by., FUN = svytotal, design = EVNTdsgn)',
    event = 'results <- svyby(~count, by = ~Condition + event,FUN = svytotal, design = EVNTdsgn)',
    sop   = 'results <- svyby(~(XP.yy.X > 0) + (SF.yy.X > 0) + (MR.yy.X > 0) + (MD.yy.X > 0) + (PR.yy.X > 0) + (OZ.yy.X > 0),\nby = ~Condition, FUN = svytotal, design = EVNTdsgn)'
  ),
  meanEXP = list(
    demo  = 'results <- svyby(~XP.yy.X, by = ~Condition + .by., FUN = svymean, design = PERSdsgn)',
    event = 'results <- svyby(~XP.yy.X, by = ~Condition + event,FUN = svymean, design = PERSevnt)',
    sop   = 'results <- svyby(~XP.yy.X + SF.yy.X + MR.yy.X + MD.yy.X + PR.yy.X + OZ.yy.X, by = ~Condition, FUN = svymean, design = PERSdsgn)'
  ),
  n = list(
    demo  = 'results <- svyby(~count, FUN = unwtd.count, by = ~Condition + .by., design = PERSdsgn)',
    event = 'results <- svyby(~count, FUN = unwtd.count, by = ~Condition + event, design = PERSevnt)',
    sop   = 'results <- svyby(~count, FUN = unwtd.count, by = ~Condition + sop, design = subset(ndsgn, XP > 0))'
  ),
  n_exp = list(
    demo  = 'results <- svyby(~count, FUN = unwtd.count, by = ~Condition + .by., design = subset(PERSdsgn, XP.yy.X > 0))',
    event = 'results <- svyby(~count, FUN = unwtd.count, by = ~Condition + event, design = subset(PERSevnt, XP.yy.X > 0))',
    sop   = 'results <- svyby(~count, FUN = unwtd.count, by = ~Condition + sop, design = subset(ndsgn, XP > 0))'
  )
)
