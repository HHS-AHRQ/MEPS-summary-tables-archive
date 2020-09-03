setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
library(tidyverse)
library(survey)
library(MEPS)
library(haven)

source("../r/functions.R")
source("dictionaries.R")
source("functions_run.R")

apps <- c("hc_use", "hc_care", "hc_ins", "hc_cond_icd10", "hc_pmed") #"hc_cond"

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

  # Create new tables for data year -- takes about 3 hours
 
  source("run_ins.R")  # ~ 4 min
  source("run_pmed.R") # ~ 2 min 
  source("run_care.R") # ~ 21 min
  source("run_cond.R") # ~ 20 min.
  source("run_use.R")  # ~ 1 hr 

  
  


  # QC tables for new year -- need to update for hc_cond_icd10 to include more years
    log_file <- "update_files/update_log.txt"
    source("check_UPDATE.R")
  

  ## STOP!! CHECK LOG (update_files/update_log.txt) before proceeding
  
    
  ## Transfer hc_cond_icd10 tables here before formatting
    
  
# Format tables and create HTML / JSON files ----------------------------------
  
  # Format tables to include in formatted_tables folder
  # totPOP for 'Any event' is updated -- old version was including all people, including those with no events
    source("tables_format.R")  
  
  # Update MASTER datasets
    source("../r/Update_master.R")
  
  # Run RtoHTML to update web pages with new year
    source("../r/RtoHTML.R", chdir = T)
  
  # Run RtoJSON to update JSON data with new year
    write_data  = T
    write_notes = TRUE
    source("../r/RtoJSON.R", chdir = T)
  