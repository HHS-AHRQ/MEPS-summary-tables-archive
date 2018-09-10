setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
library(tidyverse)

apps <- c("hc_use", "hc_care", "hc_ins", "hc_cond", "hc_pmed")
#apps <- c("hc_use", "hc_care", "hc_ins", "hc_pmed")


# Year (or years) that needs to be run
  year_list <- 2016 
  hc_year <- max(year_list)

# Set local directory for storing PUFs
  # mydir = "/Users/emilymitchell/Desktop/MEPS"
  mydir = "C:/MEPS"
  

# Create tables for new data year ---------------------------------------------

  # Update text strings for codes (only needed if codes are updated)
    source("build_codes.R")
  
  # Transfer any new PUFs to local directory (C:/MEPS)
    source("transfer_pufs.R")
  
  # Create new tables for new data year -- takes about 3 hours
    source("tables_run.R")  
  
  # QC tables for new year
    log_file <- "update_files/update_log.txt"
    source("check_UPDATE.R")
  
  
  ## STOP!! CHECK LOG (update_files/update_log.txt) before proceeding
  
  
  
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
  