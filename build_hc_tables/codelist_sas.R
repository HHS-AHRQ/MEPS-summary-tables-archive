
# Create SAS code lists -------------------------------------------------------

library(dplyr)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../r/functions.R")
source("dictionaries.R")

sas_dir = "code/sas"

loadPkgs <- dsgnCode <- NULL
loadFYC <- loadCode <- statCode <- list()


# Define code for grps --------------------------------------------------------
  SASgrps <- list.files(sprintf("%s/grps",sas_dir)) %>% gsub(".sas","",.)
  
  grpCode <- list()
  for(g in SASgrps) {
    grpCode[[g]] <- readSource(sprintf("grps/%s.sas",g), dir = sas_dir)
  }
  
  # hc_ins: Add for ins_lt65 and ins_ge65 
  grpCode[['ins_lt65']] <- grpCode[['ins_ge65']] <- grpCode[['insurance']]

  
# Use, expenditures, and population -------------------------------------------
  
  loadFYC[['hc_use']] <- readSource("load/load_fyc.sas", dir = sas_dir)
  
  loadCode[['hc_use']] <-
    list(
      totEVT = paste(
        readSource("load/event_macro.sas", dir = sas_dir),
        readSource("load/load_events.sas", dir = sas_dir),
        readSource("load/stack_events.sas", dir = sas_dir),
        readSource("load/merge_events.sas", dir = sas_dir), sep = "\n"
      ),
      meanEVT = paste(
        readSource("load/event_macro.sas", dir = sas_dir),
        readSource("load/load_events.sas", dir = sas_dir),
        readSource("load/stack_events.sas", dir = sas_dir),
        readSource("load/merge_events.sas", dir = sas_dir), sep = "\n"
      ),
      avgEVT = paste(
        readSource("load/event_macro.sas", dir = sas_dir),
        readSource("load/load_events.sas", dir = sas_dir)
      )
    )
  
  # surveymeans codes
  app_dir <- sprintf("%s/stats_use", sas_dir)
  
  use_codes <- list()
  for(code in list.files(app_dir)){
    el <- code %>% gsub(".sas","",.) %>% strsplit("__")
    stat <- el[[1]][1]
    grp  <- el[[1]][2]
  
    use_codes[[stat]][[grp]] <- readSource(code, dir = app_dir)
  }
  
  statCode[['hc_use']] <- use_codes

# Health Insurance ------------------------------------------------------------
  loadFYC[['hc_ins']] <- readSource("load/load_fyc.sas", dir = sas_dir)
  
  # surveymeans codes
  app_dir <- sprintf("%s/stats_ins", sas_dir)
  
  ins_codes <- list()
  for(code in list.files(app_dir)){
    grp <- code %>% gsub(".sas","",.) 
    ins_codes[[grp]] <- readSource(code, dir = app_dir)
  }
  
  statCode[['hc_ins']] <- 
    list(
      totPOP = ins_codes,
      pctPOP = ins_codes
    )
  

# Accessibility and Quality of Care -------------------------------------------
  
  # Care app starts after 2001
  loadFYC[['hc_care']] <- readSource("load/load_fyc_post2001.sas", dir = sas_dir)
  
  app_dir <- sprintf("%s/stats_care", sas_dir)
  
  ins_codes <- list()
  for(code in list.files(app_dir)){
    grp <- code %>% gsub(".sas","",.) 
    ins_codes[[grp]] <- readSource(code, dir = app_dir) %>%
      rsub(freq_fmt = care_freq_sas, type = 'sas')
  }
  
  statCode[['hc_care']] <- 
    list(
      totPOP = ins_codes,
      pctPOP = ins_codes
    )

  
# Prescribed Drugs ------------------------------------------------------------
  
  tc1_format <- readSource("code/sas/load/tc1_format.sas")
  
  loadCode[['hc_pmed']] = readSource("load/load_RX.sas", dir = sas_dir)

  # surveymeans codes
  app_dir <- sprintf("%s/stats_pmed", sas_dir)
  
  pmed_codes <- list()
  for(code in list.files(app_dir)){
    el <- code %>% gsub(".sas","",.) %>% strsplit("__")
    stat <- el[[1]][1]
    grp  <- el[[1]][2]
    
    pmed_codes[[stat]][[grp]] <- 
      readSource(code, dir = app_dir) %>%
      rsub(tc1_fmt = tc1_format, type = 'sas')
  }
  
  statCode[['hc_pmed']] <- pmed_codes
  
  
# Medical Conditions -----------------------------------------------------------
  
  loadFYC[['hc_cond']] <- paste(
    readSource("load/cond_format.sas", dir = sas_dir),
    readSource("load/event_macro.sas", dir = sas_dir),
    readSource("load/load_fyc.sas", dir = sas_dir), sep = "\n")
  
  loadCode[['hc_cond']] <- readSource("load/load_cond.sas", dir = sas_dir) 
  
  # surveymeans codes
  app_dir <- sprintf("%s/stats_cond", sas_dir)
  
  cond_codes <- list()
  for(code in list.files(app_dir)){
    el <- code %>% gsub(".sas","",.) %>% strsplit("__")
    stat <- el[[1]][1]
    grp  <- el[[1]][2]
    
    cond_codes[[stat]][[grp]] <- 
      readSource(code, dir = app_dir) 
  }
  
  statCode[['hc_cond']] <- cond_codes





