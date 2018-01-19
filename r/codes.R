# Table code lists ------------------------------------------------------------

library(dplyr)

# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
# source("functions.R")
# source("dictionaries.R")

tc1_format <- readSource("../code/sas/load/tc1_format.sas")

build_sas_codes <- function(stats, grps, app, ignore_stat_name = F) {
  sas_codes <- list()
  for(s in stats) {
    temp <- list()
    for(g in grps) {
      if(ignore_stat_name) sname = g else sname = sprintf("%s_%s",s,g)
      cname = sprintf("stats_%s/%s.sas", app, sname)
      temp[[g]] =  readSource(cname, dir = sas_dir) %>%
        rsub(freq_fmt = care_freq_sas,
             tc1_fmt = tc1_format,
             type = 'sas')
    }
    sas_codes[[s]] = temp
  }
  return(sas_codes)
}


r_dir   = "../code/r"
sas_dir = "../code/sas"

loadFYC <- loadCode <- dsgnCode <- statCode <- list()
loadPkgs <- list(R = readSource("load/load_pkg.R", dir = r_dir))

# Define code for grps --------------------------------------------------------
  Rgrps   <- list.files(sprintf("%s/grps",r_dir))   %>% gsub(".R","",.)
  SASgrps <- list.files(sprintf("%s/grps",sas_dir)) %>% gsub(".sas","",.)

  RgrpCode <- SASgrpCode <- list()
  for(g in Rgrps) {
    RgrpCode[[g]] <- readSource(sprintf("grps/%s.R",g), dir = r_dir) %>%
      rsub(freq = care_freq)
  }
  for(g in SASgrps) {
    SASgrpCode[[g]] <- readSource(sprintf("grps/%s.sas",g), dir = sas_dir)
  }

  # Add for ins_lt65 and ins_ge65
  RgrpCode[['ins_lt65']] <- RgrpCode[['ins_ge65']] <- RgrpCode[['insurance']]
  SASgrpCode[['ins_lt65']] <- SASgrpCode[['ins_ge65']] <- SASgrpCode[['insurance']]

  grpCode <- list('R' = RgrpCode, 'SAS' = SASgrpCode)


# Define loadFYC code (empty for PMED) ----------------------------------------

  loadFYC[['use']] <- loadFYC[['ins']] <- loadFYC[['cond']] <-
    list(
      R   = readSource("load/load_fyc.R",   dir = r_dir),
      SAS = readSource("load/load_fyc.sas", dir = sas_dir)
    )

  # Care app starts after 2001
  loadFYC[['care']] <-
    list(
      R   = readSource("load/load_fyc_post2001.R",   dir = r_dir),
      SAS = readSource("load/load_fyc_post2001.sas", dir = sas_dir)
    )


# Use, expenditures, and population -------------------------------------------

  loadCode[['use']] = list(
    R = list(
      totEVT = paste(
        readSource("load/load_events.R", dir = r_dir),
        readSource("load/stack_events.R", dir = r_dir),
        readSource("load/merge_events.R", dir = r_dir), sep = "\n"
      ),
      meanEVT = paste(
        readSource("load/load_events.R", dir = r_dir),
        readSource("load/stack_events.R", dir = r_dir),
        readSource("load/merge_events.R", dir = r_dir), sep = "\n"
      ),
      avgEVT = paste(
        readSource("load/load_events.R", dir = r_dir),
        readSource("load/stack_events.R", dir = r_dir), sep = "\n"
      )
    ),

    SAS = list(
      totEVT = paste(
        readSource("load/load_events.sas", dir = sas_dir),
        readSource("load/stack_events.sas", dir = sas_dir),
        readSource("load/merge_events.sas", dir = sas_dir), sep = "\n"
      ),
      meanEVT = paste(
        readSource("load/load_events.sas", dir = sas_dir),
        readSource("load/stack_events.sas", dir = sas_dir),
        readSource("load/merge_events.sas", dir = sas_dir), sep = "\n"
      ),
      avgEVT = paste(
        readSource("load/load_events.sas", dir = sas_dir)
      )
    )
  )


  dsgnCode[['use']] = list(
    R = list(
      totEVT  = readSource("dsgn/use_EVNT.R", dir = r_dir),
      meanEVT = readSource("dsgn/use_EVNT.R", dir = r_dir),

      avgEVT  = list(
        demo  = readSource("dsgn/use_nEVNT.R", dir = r_dir),
        sop   = readSource("dsgn/use_nEVNT.R", dir = r_dir)
      ),

      demo = readSource("dsgn/all_FYC.R", dir = r_dir),
      sop = readSource("dsgn/all_FYC.R", dir = r_dir)
    )
  )
  
  use_stats <- unlist(statList[['use']])

  # R codes
    use_stats_R <- list()
    for(stat in c(use_stats, "n", "n_exp")){
      use_stats_R[[stat]] <- source(sprintf("%s/stats_use/%s.R", r_dir, stat))$value
    }

  statCode[['use']] = list(
    R   = use_stats_R,
    
    SAS = build_sas_codes(
      app = "use",
      stats = use_stats,
      grps  = c("demo", "event", "sop", "event_sop"))
  )


# Health Insurance ------------------------------------------------------------

dsgnCode[['ins']] = list(
  R = list( demo = readSource("dsgn/all_FYC.R", dir = r_dir) )
)

ins_stats <- list(
  insurance = 'svyby(~insurance, FUN = .FUN., by = ~.by., design = FYCdsgn)',
  ins_lt65  = 'svyby(~insurance_v2X, FUN = .FUN., by = ~.by., design = subset(FYCdsgn, AGELAST < 65))',
  ins_ge65  = 'svyby(~insurance_v2X, FUN = .FUN., by = ~.by., design = subset(FYCdsgn, AGELAST >= 65))'
)

statCode[['ins']] = list(
  R = list(
    totPOP = lapply(ins_stats, function(x) rsub(x, FUN = "svytotal")),
    pctPOP = lapply(ins_stats, function(x) rsub(x, FUN = "svymean")),
    n      = lapply(ins_stats, function(x) rsub(x, FUN = "unwtd.count"))
  ),

  SAS = build_sas_codes(ignore_stat_name = T,
      app = "ins",
      stats = c("totPOP", "pctPOP"),
      grps  = colGrps_R[['ins']])
)


# Accessibility and Quality of Care -------------------------------------------

dsgnCode[['care']] = list(
  R = list(
      adult = readSource("dsgn/care_SAQ.R",  dir = r_dir),
      diab  = readSource("dsgn/care_DIAB.R", dir = r_dir),
      demo  = readSource("dsgn/all_FYC.R",   dir = r_dir)
  )
)

care_stats <- list(
  usc = 'svyby(~usc, FUN = .FUN., by = ~.by., design = subset(FYCdsgn, ACCELI42==1 & HAVEUS42 >= 0 & LOCATN42 >= -1))',

  difficulty ='svyby(~delay_ANY + delay_MD + delay_DN + delay_PM, FUN = .FUN., by = ~.by., design = subset(FYCdsgn, ACCELI42==1))',

  rsn_ANY = 'svyby(~afford_ANY + insure_ANY + other_ANY, FUN = .FUN., by = ~.by., design = subset(FYCdsgn, ACCELI42==1 & delay_ANY==1))',
  rsn_MD = 'svyby(~afford_MD + insure_MD + other_MD, FUN = .FUN., by = ~.by., design = subset(FYCdsgn, ACCELI42==1 & delay_MD==1))',
  rsn_DN = 'svyby(~afford_DN + insure_DN + other_DN, FUN = .FUN., by = ~.by., design = subset(FYCdsgn, ACCELI42==1 & delay_DN==1))',
  rsn_PM = 'svyby(~afford_PM + insure_PM + other_PM, FUN = .FUN., by = ~.by., design = subset(FYCdsgn, ACCELI42==1 & delay_PM==1))',

  diab_a1c  = 'svyby(~diab_a1c, FUN = .FUN., by = ~.by., design = DIABdsgn)',
  diab_eye  = 'svyby(~diab_eye, FUN = .FUN., by = ~.by., design = DIABdsgn)',
  diab_flu  = 'svyby(~diab_flu, FUN = .FUN., by = ~.by., design = DIABdsgn)',
  diab_chol = 'svyby(~diab_chol, FUN = .FUN., by = ~.by., design = DIABdsgn)',
  diab_foot = 'svyby(~diab_foot, FUN = .FUN., by = ~.by., design = DIABdsgn)',

  adult_nosmok  = 'svyby(~adult_nosmok, FUN = .FUN., by = ~.by., design = subset(SAQdsgn, ADSMOK42==1 & CHECK53==1))',
  adult_routine = 'svyby(~adult_routine, FUN = .FUN., by = ~.by., design = subset(SAQdsgn, ADRTCR42==1 & AGELAST >= 18))',
  adult_illness = 'svyby(~adult_illness, FUN = .FUN., by = ~.by., design = subset(SAQdsgn, ADILCR42==1 & AGELAST >= 18))',

  child_dental  = 'svyby(~child_dental, FUN = .FUN., by = ~.by., design = subset(FYCdsgn, child_2to17==1))',
  child_routine = 'svyby(~child_routine, FUN = .FUN., by = ~.by., design = subset(FYCdsgn, CHRTCR42==1 & AGELAST < 18))',
  child_illness = 'svyby(~child_illness, FUN = .FUN., by = ~.by., design = subset(FYCdsgn, CHILCR42==1 & AGELAST < 18))',

  adult_time    = 'svyby(~adult_time, FUN=.FUN., by = ~.by., design = subset(SAQdsgn, ADAPPT42 >= 1 & AGELAST >= 18))',
  adult_listen  = 'svyby(~adult_listen, FUN=.FUN., by = ~.by., design = subset(SAQdsgn, ADAPPT42 >= 1 & AGELAST >= 18))',
  adult_rating  = 'svyby(~adult_rating, FUN=.FUN., by = ~.by., design = subset(SAQdsgn, ADAPPT42 >= 1 & AGELAST >= 18))',
  adult_respect = 'svyby(~adult_respect, FUN=.FUN., by = ~.by., design = subset(SAQdsgn, ADAPPT42 >= 1 & AGELAST >= 18))',
  adult_explain = 'svyby(~adult_explain, FUN=.FUN., by = ~.by., design = subset(SAQdsgn, ADAPPT42 >= 1 & AGELAST >= 18))',

  child_time    = 'svyby(~child_time, FUN=.FUN., by = ~.by., design = subset(FYCdsgn, CHAPPT42 >= 1 & AGELAST < 18))',
  child_listen  = 'svyby(~child_listen, FUN=.FUN., by = ~.by., design = subset(FYCdsgn, CHAPPT42 >= 1 & AGELAST < 18))',
  child_rating  = 'svyby(~child_rating, FUN=.FUN., by = ~.by., design = subset(FYCdsgn, CHAPPT42 >= 1 & AGELAST < 18))',
  child_respect = 'svyby(~child_respect, FUN=.FUN., by = ~.by., design = subset(FYCdsgn, CHAPPT42 >= 1 & AGELAST < 18))',
  child_explain = 'svyby(~child_explain, FUN=.FUN., by = ~.by., design = subset(FYCdsgn, CHAPPT42 >= 1 & AGELAST < 18))'
)

statCode[['care']] = list(
  R = list(
    totPOP = lapply(care_stats, function(x) rsub(x, FUN = "svytotal")),
    pctPOP = lapply(care_stats, function(x) rsub(x, FUN = "svymean")),
    n      = lapply(care_stats, function(x) rsub(x, FUN = "unwtd.count"))
  ),

  SAS = build_sas_codes(ignore_stat_name = T,
      app = "care",
      stats = c("totPOP", "pctPOP"),
      grps  = colGrps_R[['care']])
)


# Prescribed Drugs ------------------------------------------------------------

loadCode[['pmed']] = list(
  R   = readSource("load/load_RX.R",   dir = r_dir),
  SAS = readSource("load/load_RX.sas", dir = sas_dir)
)

dsgnCode[['pmed']] = list(
  R = list(
    RXDRGNAM = readSource("dsgn/pmed_RX.R", dir = r_dir),
    TC1name  = readSource("dsgn/pmed_RX.R", dir = r_dir),

    totPOP = list(
      RXDRGNAM = readSource("dsgn/pmed_DRG.R", dir = r_dir),
      TC1name  = readSource("dsgn/pmed_TC1.R", dir = r_dir)
    )
  )
)

statCode[['pmed']] = list(
  R = list(
    totPOP = list(
      RXDRGNAM = 'svyby(~count, by = ~RXDRGNAM, FUN = svytotal, design = DRGdsgn)',
      TC1name  = 'svyby(~count, by = ~TC1name, FUN = svytotal, design = TC1dsgn)'
    ),
    totEXP = list(
      RXDRGNAM = 'svyby(~RXXP.yy.X, by = ~RXDRGNAM, FUN = svytotal, design = subset(RXdsgn, RXNDC != "-9" & RXDRGNAM != "-9"))',
      TC1name  = 'svyby(~RXXP.yy.X, by = ~TC1name, FUN = svytotal, design = RXdsgn)'
    ),
    totEVT = list(
      RXDRGNAM = 'svyby(~count, by = ~RXDRGNAM, FUN = svytotal, design = subset(RXdsgn, RXNDC != "-9" & RXDRGNAM != "-9"))',
      TC1name  = 'svyby(~count, by = ~TC1name, FUN = svytotal, design = RXdsgn)'
    ),
    n = list(
      RXDRGNAM = 'svyby(~count, by = ~RXDRGNAM, FUN = unwtd.count, design = DRGdsgn)',
      TC1name  = 'svyby(~count, by = ~TC1name, FUN = unwtd.count, design = TC1dsgn)'
    )
  ),

  SAS = build_sas_codes(
    app = "pmed",
    stats = c("totPOP", "totEXP", "totEVT"),
    grps  = c("RXDRGNAM", "TC1name"))

)


# Medical Conditions -----------------------------------------------------------

cond_fmt <- readSource("../code/sas/load/cond_format.sas")

loadCode[['cond']] = list(
  R = paste(
    readSource("load/load_events.R",  dir = r_dir),
    readSource("load/load_cond.R",    dir = r_dir), sep = "\n"
    ),

  SAS = paste(
    readSource("load/load_events.sas", dir = sas_dir),
    readSource("load/load_cond.sas",   dir = sas_dir) %>%
      rsub(cond_format = cond_fmt, type = 'sas'), sep = "\n")
)

dsgnCode[['cond']] = list(
  R = list(

    totPOP = list(
      demo  = readSource("dsgn/cond_PERS.R", dir = r_dir),
      event = readSource("dsgn/cond_PRSEV.R", dir = r_dir),
      sop   = readSource("dsgn/cond_PERS.R", dir = r_dir)
    ),

    totEXP = list(
      demo  = readSource("dsgn/cond_EVNT.R", dir = r_dir),
      event = readSource("dsgn/cond_PRSEV.R", dir = r_dir),
      sop   = readSource("dsgn/cond_EVNT.R", dir = r_dir)
    ),

    totEVT = readSource("dsgn/cond_EVNT.R", dir = r_dir),

    meanEXP = list(
      demo  = readSource("dsgn/cond_PERS.R", dir = r_dir),
      event = readSource("dsgn/cond_PRSEV.R", dir = r_dir),
      sop   = readSource("dsgn/cond_PERS.R", dir = r_dir)
    ),

    n = readSource("dsgn/cond_N.R", dir = r_dir)
  )
)


statCode[['cond']] = list(
  R = list(
    totPOP = list(
      demo  = 'svyby(~count, by = ~Condition + .by., FUN = svytotal, design = PERSdsgn)',
      event = 'svyby(~count, by = ~Condition + event, FUN = svytotal, design = PERSevnt)',
      sop   = 'svyby(~(XP.yy.X > 0) + (SF.yy.X > 0) + (MR.yy.X > 0) + (MD.yy.X > 0) + (PR.yy.X > 0) + (OZ.yy.X > 0),\n by = ~Condition, FUN = svytotal, design = PERSdsgn)'
    ),
    totEXP = list(
      demo  = 'svyby(~XP.yy.X, by = ~Condition + .by., FUN = svytotal, design = EVNTdsgn)',
      event = 'svyby(~XP.yy.X, by = ~Condition + event, FUN = svytotal, design = PERSevnt)',
      sop   = 'svyby(~XP.yy.X + SF.yy.X + MR.yy.X + MD.yy.X + PR.yy.X + OZ.yy.X, by = ~Condition, FUN = svytotal, design = EVNTdsgn)'
    ),
    totEVT = list(
      demo  = 'svyby(~count, by = ~Condition + .by., FUN = svytotal, design = EVNTdsgn)',
      event = 'svyby(~count, by = ~Condition + event,FUN = svytotal, design = EVNTdsgn)',
      sop   = 'svyby(~(XP.yy.X > 0) + (SF.yy.X > 0) + (MR.yy.X > 0) + (MD.yy.X > 0) + (PR.yy.X > 0) + (OZ.yy.X > 0),\nby = ~Condition, FUN = svytotal, design = EVNTdsgn)'
    ),
    meanEXP = list(
      demo  = 'svyby(~XP.yy.X, by = ~Condition + .by., FUN = svymean, design = PERSdsgn)',
      event = 'svyby(~XP.yy.X, by = ~Condition + event,FUN = svymean, design = PERSevnt)',
      sop   = 'svyby(~XP.yy.X + SF.yy.X + MR.yy.X + MD.yy.X + PR.yy.X + OZ.yy.X, by = ~Condition, FUN = svymean, design = PERSdsgn)'
    ),
    n = list(
      demo  = 'svyby(~count, FUN = unwtd.count, by = ~Condition + .by., design = PERSdsgn)',
      event = 'svyby(~count, FUN = unwtd.count, by = ~Condition + event, design = PERSevnt)',
      sop   = 'svyby(~count, FUN = unwtd.count, by = ~Condition + sop, design = subset(ndsgn, XP > 0))'
    ),
    n_exp = list(
      demo  = 'svyby(~count, FUN = unwtd.count, by = ~Condition + .by., design = subset(PERSdsgn, XP.yy.X > 0))',
      event = 'svyby(~count, FUN = unwtd.count, by = ~Condition + event, design = subset(PERSevnt, XP.yy.X > 0))',
      sop   = 'svyby(~count, FUN = unwtd.count, by = ~Condition + sop, design = subset(ndsgn, XP > 0))'
    )
  ),

  SAS = build_sas_codes(
    app = "cond",
    stats = c("totPOP", "totEXP", "totEVT", "meanEXP"),
    grps  = c("demo", "event", "sop"))
)
