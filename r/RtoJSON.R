# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(tidyverse)
library(stringr)
library(jsonlite)
library(MEPS)

source("functions.R")
source("functions_toJSON.R")

source("app_info_hc.R")
source("app_notes_hc.R")


# write_data  = TRUE
# write_notes = TRUE


# HC tables -------------------------------------------------------------------

notes <- list()

# Use, expenditures, and population ---------------------------------

notes[['hc_use']] <- 
  list(totEVT  = EVT,
       meanEVT = EVT,
       avgEVT  = EVT,
       
       totEXP   = EXP,
       meanEXP  = EXP,
       meanEXP0 = EXP,
       medEXP   = paste(EXP, median),
       
       event = event,
       sop   = sop) %>% append(demographics)

if(write_data)  data_toJSON(appKey = 'hc_use', pivot = F)
if(write_notes) notes_toJSON(appKey = 'hc_use', notes = notes[['hc_use']])


# Health insurance --------------------------------------------------
notes[['hc_ins']] <- 
  list(pctPOP = rounding) %>% 
  append(demographics)

if(write_data)  data_toJSON(appKey = 'hc_ins', pivot = F)
if(write_notes) notes_toJSON(appKey = 'hc_ins', notes = notes[['hc_ins']])

# Accessibility and quality of care ---------------------------------

notes[['hc_care']] <- 
  list(pctPOP = rounding,
       usc = usc,
       diab_eye = diab_eye,
       diab_foot = diab_foot,
       adult_nosmok = adult_nosmok,
       difficulty = difficulty,
       rsn_ANY = rsn_difficulty,
       rsn_MD = rsn_difficulty,
       rsn_DN = rsn_difficulty,
       rsn_PM = rsn_difficulty) %>% 
  append(demographics)

if(write_data)  data_toJSON(appKey = 'hc_care', pivot = F)
if(write_notes) notes_toJSON(appKey = 'hc_care', notes = notes[['hc_care']])

# Medical conditions, 1996-2015 -----------------------------------------------

notes[['hc_cond']] <- 
  list(totEVT  = EVT2,
       totEXP  = EXP,
       meanEXP = EXP,
       Condition = Condition,
       event = event_cond,
       sop   = sop) %>% 
  append(demographics)

if(write_data)  data_toJSON(appKey = 'hc_cond', pivot = T)
if(write_notes) notes_toJSON(appKey = 'hc_cond', notes = notes[['hc_cond']])


# Medical conditions, 2016-current --------------------------------------------

notes[['hc_cond_icd10']] <- 
  list(totEVT  = EVT2,
       totEXP  = EXP,
       meanEXP = EXP,
       Condition = Condition,
       event = event_cond,
       sop   = sop) %>% 
  append(demographics)

if(write_data)  data_toJSON(appKey = 'hc_cond_icd10', pivot = T)
if(write_notes) notes_toJSON(appKey = 'hc_cond_icd10', notes = notes[['hc_cond_icd10']])



# Prescribed Drugs --------------------------------------------------

notes[['hc_pmed']] <-
  list(RXDRGNAM = RXDRGNAM,
       TC1name = TC1name)

if(write_data)  data_toJSON(appKey = 'hc_pmed', pivot = T)
if(write_notes) notes_toJSON(appKey = 'hc_pmed', notes = notes[['hc_pmed']])

