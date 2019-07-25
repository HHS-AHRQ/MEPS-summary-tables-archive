setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
library(tidyverse)
library(survey)
library(MEPS)

source("../r/functions.R")
source("dictionaries.R")
source("functions_run.R")


apps <- c("hc_use", "hc_care", "hc_ins", "hc_cond", "hc_cond_icd10", "hc_pmed")
#apps <- c("hc_use", "hc_care", "hc_ins", "hc_pmed")


# Year (or years) that needs to be run
  year_list <- 2016 
  hc_year <- max(year_list)

# Set local directory for storing PUFs
  # mydir = "/Users/emilymitchell/Desktop/MEPS"
  mydir = "C:/MEPS"
  

# Create tables for new data year ---------------------------------------------

  ## !! For hc_cond icd10 versions (2016, 2017), need to build tables on secure
  ## !! LAN, since CCS codes are not on PUFs 
  
  # Update text strings for codes (only needed if codes are updated)
    source("build_codes.R")
  
  # Transfer any new PUFs to local directory (C:/MEPS)
    source("transfer_pufs.R")
  
  # Create new tables for new data year -- takes about 3 hours
    source("codelist_r.R")
    run_tables(appKey = 'hc_care', year_list = year_list) # ~20 min
    run_tables(appKey = 'hc_pmed', year_list = year_list) # 2 min
    run_tables(appKey = 'hc_ins',  year_list = year_list) # 4 min
    run_tables(appKey = 'hc_cond', year_list = year_list[year_list <= 2015]) # ~20 min
    
    run_tables(appKey = 'hc_use',  year_list = year_list) # 2 hrs

  # QC tables for new year
    log_file <- "update_files/update_log.txt"
    source("check_UPDATE.R")
  
  
  ## STOP!! CHECK LOG (update_files/update_log.txt) before proceeding
  
    
  ## Transfer hc_cond_icd10 tables here before formatting
    
  
# Format tables and create HTML / JSON files ----------------------------------
  
  # Format tables to include in formatted_tables folder
    source("tables_format.R") 
  
  # Update MASTER datasets
    source("../r/Update_master.R")
  
  # Run RtoHTML to update web pages with new year
    source("../r/RtoHTML.R", chdir = T)
  
  # Run RtoJSON to update JSON data with new year
    write_data  = TRUE
    write_notes = TRUE
    source("../r/RtoJSON.R", chdir = T)
  