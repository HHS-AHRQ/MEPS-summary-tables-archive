setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
library(tidyverse)
library(survey)
library(MEPS)
library(haven)

source("../r/functions.R")
source("dictionaries.R")
source("functions_run.R")

apps <- c("hc_use", "hc_care", "hc_ins", "hc_cond", "hc_cond_icd10", "hc_pmed")

# Year (or years) that needs to be run
  year_list <- 2018:2017
  hc_year <- max(year_list)

# Set local directory for storing PUFs
  # mydir = "/Users/emilymitchell/Desktop/MEPS"
  mydir = "C:/MEPS"
  

# Optional: rename existing folder to QC code on previous years ---------------    
# # still working on this part...
# for(year in year_list) { print(year)
#   for(app in apps) {
#     existing_folder = str_glue("data_tables/{app}/{year}")
#     if(!existing_folder %in% 
#        list.files(str_glue("data_tables/{app}"), full.names = T)) {
#       next
#     }
#     folder_copy = str_glue("data_tables/{app}/{year} - orig")
#     dir.create(folder_copy)
#     files <- list.files(existing_folder, full.names = T)
#     file.copy(from = files, to = folder_copy)
#     unlink(existing_folder, recursive = T)
#   }
# }
  
  
  
# Create tables for new data year ---------------------------------------------

  ## !! For hc_cond icd10 versions (2016, 2017), need to build tables on secure
  ## !! LAN, since CCSR codes are not on PUFs 

  
  # Transfer any new PUFs to local directory (C:/MEPS)
  source("transfer_pufs.R")
  
  # Create new tables for data year -- takes about 3 hours
  source("run_ins.R")  # ~ 4 min
  source("run_care.R") # ~ 21 min
  source("run_pmed.R") # ~ 2 min
  source("run_cond.R") # ~ 20 min. 
  source("run_use.R")  # ~ 1 hr
  
  
  # OLD CODE ----------------------------------------------------------------
  # Update text strings for codes (only needed if codes are updated)
    #source("build_codes.R")
  

  # Create new tables for new data year -- takes about 3 hours
    #source("codelist_r.R")

    #run_tables(appKey = 'hc_care', year_list = year_list[year_list >= 2002]) # ~20 min
    #run_tables(appKey = 'hc_pmed', year_list = year_list) # 2 min -- doing this now
    #run_tables(appKey = 'hc_ins',  year_list = year_list) # 4 min
    #run_tables(appKey = 'hc_cond', year_list = year_list[year_list <= 2015]) # ~20 min
    #run_tables(appKey = 'hc_use',  year_list = year_list) # 2 hrs
  # END OLD CODE ----------------------------------------------------------------
    
    
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
    write_data  = FALSE
    write_notes = TRUE
    source("../r/RtoJSON.R", chdir = T)
  