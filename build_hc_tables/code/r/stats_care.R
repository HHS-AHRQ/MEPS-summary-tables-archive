
care_stats <- list(
  usc = 'results <- svyby(~usc, FUN = .FUN., by = ~.by., design = subset(FYCdsgn, ACCELI42==1 & HAVEUS42 >= 0 & LOCATN42 >= -1))',

  difficulty ='results <- svyby(~delay_ANY + delay_MD + delay_DN + delay_PM, FUN = .FUN., by = ~.by., design = subset(FYCdsgn, ACCELI42==1))',

  rsn_ANY = 'results <- svyby(~afford_ANY + insure_ANY + other_ANY, FUN = .FUN., by = ~.by., design = subset(FYCdsgn, ACCELI42==1 & delay_ANY==1))',
  rsn_MD = 'results <- svyby(~afford_MD + insure_MD + other_MD, FUN = .FUN., by = ~.by., design = subset(FYCdsgn, ACCELI42==1 & delay_MD==1))',
  rsn_DN = 'results <- svyby(~afford_DN + insure_DN + other_DN, FUN = .FUN., by = ~.by., design = subset(FYCdsgn, ACCELI42==1 & delay_DN==1))',
  rsn_PM = 'results <- svyby(~afford_PM + insure_PM + other_PM, FUN = .FUN., by = ~.by., design = subset(FYCdsgn, ACCELI42==1 & delay_PM==1))',

  diab_a1c  = 'results <- svyby(~diab_a1c, FUN = .FUN., by = ~.by., design = DIABdsgn)',
  diab_eye  = 'results <- svyby(~diab_eye, FUN = .FUN., by = ~.by., design = DIABdsgn)',
  diab_flu  = 'results <- svyby(~diab_flu, FUN = .FUN., by = ~.by., design = DIABdsgn)',
  diab_chol = 'results <- svyby(~diab_chol, FUN = .FUN., by = ~.by., design = DIABdsgn)',
  diab_foot = 'results <- svyby(~diab_foot, FUN = .FUN., by = ~.by., design = DIABdsgn)',

  adult_nosmok  = 'results <- svyby(~adult_nosmok, FUN = .FUN., by = ~.by., design = subset(SAQdsgn, ADSMOK42==1 & CHECK53==1))',
  adult_routine = 'results <- svyby(~adult_routine, FUN = .FUN., by = ~.by., design = subset(SAQdsgn, ADRTCR42==1 & AGELAST >= 18))',
  adult_illness = 'results <- svyby(~adult_illness, FUN = .FUN., by = ~.by., design = subset(SAQdsgn, ADILCR42==1 & AGELAST >= 18))',

  child_dental  = 'results <- svyby(~child_dental, FUN = .FUN., by = ~.by., design = subset(FYCdsgn, child_2to17==1))',
  child_routine = 'results <- svyby(~child_routine, FUN = .FUN., by = ~.by., design = subset(FYCdsgn, CHRTCR42==1 & AGELAST < 18))',
  child_illness = 'results <- svyby(~child_illness, FUN = .FUN., by = ~.by., design = subset(FYCdsgn, CHILCR42==1 & AGELAST < 18))',

  adult_time    = 'results <- svyby(~adult_time, FUN=.FUN., by = ~.by., design = subset(SAQdsgn, ADAPPT42 >= 1 & AGELAST >= 18))',
  adult_listen  = 'results <- svyby(~adult_listen, FUN=.FUN., by = ~.by., design = subset(SAQdsgn, ADAPPT42 >= 1 & AGELAST >= 18))',
  adult_rating  = 'results <- svyby(~adult_rating, FUN=.FUN., by = ~.by., design = subset(SAQdsgn, ADAPPT42 >= 1 & AGELAST >= 18))',
  adult_respect = 'results <- svyby(~adult_respect, FUN=.FUN., by = ~.by., design = subset(SAQdsgn, ADAPPT42 >= 1 & AGELAST >= 18))',
  adult_explain = 'results <- svyby(~adult_explain, FUN=.FUN., by = ~.by., design = subset(SAQdsgn, ADAPPT42 >= 1 & AGELAST >= 18))',

  child_time    = 'results <- svyby(~child_time, FUN=.FUN., by = ~.by., design = subset(FYCdsgn, CHAPPT42 >= 1 & AGELAST < 18))',
  child_listen  = 'results <- svyby(~child_listen, FUN=.FUN., by = ~.by., design = subset(FYCdsgn, CHAPPT42 >= 1 & AGELAST < 18))',
  child_rating  = 'results <- svyby(~child_rating, FUN=.FUN., by = ~.by., design = subset(FYCdsgn, CHAPPT42 >= 1 & AGELAST < 18))',
  child_respect = 'results <- svyby(~child_respect, FUN=.FUN., by = ~.by., design = subset(FYCdsgn, CHAPPT42 >= 1 & AGELAST < 18))',
  child_explain = 'results <- svyby(~child_explain, FUN=.FUN., by = ~.by., design = subset(FYCdsgn, CHAPPT42 >= 1 & AGELAST < 18))'
)

list(
  totPOP = lapply(care_stats, function(x) rsub(x, FUN = "svytotal")),
  pctPOP = lapply(care_stats, function(x) rsub(x, FUN = "svymean")),
  n      = lapply(care_stats, function(x) rsub(x, FUN = "unwtd.count"))
)
