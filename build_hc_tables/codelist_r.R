# Table code lists ------------------------------------------------------------

library(dplyr)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../r/functions.R")
source("dictionaries.R")

r_dir = "code/r"

loadFYC <- loadCode <- dsgnCode <- statCode <- list()

loadPkgs <- readSource("load/load_pkg.R", dir = r_dir)

# Define code for grps --------------------------------------------------------
  Rgrps <- list.files(sprintf("%s/grps",r_dir)) %>% gsub(".R","",.)

  grpCode <- list()
  for(g in Rgrps) {
    grpCode[[g]] <- readSource(sprintf("grps/%s.R",g), dir = r_dir) %>%
      rsub(freq = care_freq)
  }

  # hc_ins: Add for ins_lt65 and ins_ge65 
  grpCode[['ins_lt65']] <- grpCode[['ins_ge65']] <- grpCode[['insurance']]

  # Add v2X/v3X for agegrps, insurance
  grpCode[['agegrps_v2X']] <- grpCode[['agegrps_v3X']] <- grpCode[['agegrps']]
  grpCode[['insurance_v2X']] <- grpCode[['insurance']] 
  
  
# Use, expenditures, and population -------------------------------------------

  loadFYC[['hc_use']] <- readSource("load/load_fyc.R", dir = r_dir)
  
  loadCode[['hc_use']] <- 
    list(
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
      ),
      
      DEFAULT = NULL
    )
  
  dsgnCode[['hc_use']] <- 
    list(
      totEVT  = readSource("dsgn/use_EVNT.R", dir = r_dir),
      meanEVT = readSource("dsgn/use_EVNT.R", dir = r_dir),

      avgEVT  = list(
        demo  = readSource("dsgn/use_nEVNT.R", dir = r_dir),
        sop   = readSource("dsgn/use_nEVNT.R", dir = r_dir),
        DEFAULT = NULL
      ),

      DEFAULT = readSource("dsgn/all_FYC.R", dir = r_dir)
  )
  
  # svyby codes
  for(code in list.files(sprintf("%s/stats_use",r_dir))){
    stat <- code %>% gsub(".R", "", .)
    statCode[['hc_use']][[stat]] <- source(sprintf("%s/stats_use/%s.R", r_dir, stat))$value
  }

 
# Health Insurance ------------------------------------------------------------
  
  loadFYC[['hc_ins']]  <- readSource("load/load_fyc.R", dir = r_dir)
  dsgnCode[['hc_ins']] <- readSource("dsgn/all_FYC.R", dir = r_dir)
  statCode[['hc_ins']] <- source(sprintf("%s/stats_ins.R", r_dir))$value


# Accessibility and Quality of Care -------------------------------------------
 
  loadFYC[['hc_care']] <- readSource("load/load_fyc_post2001.R", dir = r_dir)
  
  care_grps <- colGrps[['hc_care']] %>% unlist
  adult_grps <- care_grps[care_grps %>% startsWith('adult')]
  diab_grps <- care_grps[care_grps %>% startsWith('diab')]
  
  care_dsgn <- list()
  for(gg in adult_grps) care_dsgn[[gg]] <- readSource("dsgn/care_SAQ.R", dir = r_dir)
  for(gg in diab_grps) care_dsgn[[gg]] <- readSource("dsgn/care_DIAB.R", dir = r_dir)

  dsgnCode[['hc_care']] <- list(
    totPOP = care_dsgn,
    pctPOP = care_dsgn,
    DEFAULT = readSource("dsgn/all_FYC.R",   dir = r_dir)
  )
  
  statCode[['hc_care']] <- source(sprintf("%s/stats_care.R", r_dir))$value
  
  
# Prescribed Drugs ------------------------------------------------------------
  
  loadCode[['hc_pmed']] <- readSource("load/load_RX.R", dir = r_dir)
  
  dsgnCode[['hc_pmed']] <- list(

    totPOP = list(
      RXDRGNAM = readSource("dsgn/pmed_DRG.R", dir = r_dir),
      TC1name  = readSource("dsgn/pmed_TC1.R", dir = r_dir)
    ),
    
    DEFAULT = readSource("dsgn/pmed_RX.R", dir = r_dir)
  )
  
  statCode[['hc_pmed']] <- source(sprintf("%s/stats_pmed.R", r_dir))$value
  

# Medical Conditions -----------------------------------------------------------
  
  loadFYC[['hc_cond']]  <- readSource("load/load_fyc.R", dir = r_dir)
  loadCode[['hc_cond']] <- readSource("load/load_cond.R", dir = r_dir)
  
  dsgnCode[['hc_cond']] = list(
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
  
  statCode[['hc_cond']] <- source(sprintf("%s/stats_cond.R", r_dir))$value
  
  