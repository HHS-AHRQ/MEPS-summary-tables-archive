# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(dplyr)
library(tidyr)
library(survey)
library(MEPS)

source("../r/functions.R")
source("dictionaries.R")
source("functions_run.R")
source("codelist_r.R")

# -----------------------------------------------------------------------------

# Load packages locally if no internet connection is available 
# (skip install -- need to comment out loadPkgs in functions_run.R)
#   package_names <- c("survey","dplyr","foreign","devtools")
#   lapply(package_names, require, character.only=T)
#   library(MEPS)
#   options(survey.lonely.psu="adjust")


# year_list <- 1996:2015

t1 <- system.time(run_tables(appKey = 'hc_care', year_list = year_list))
t2 <- system.time(run_tables(appKey = 'hc_cond', year_list = year_list))
t3 <- system.time(run_tables(appKey = 'hc_pmed', year_list = year_list))
t4 <- system.time(run_tables(appKey = 'hc_ins',  year_list = year_list))

t5 <- system.time(run_tables(appKey = 'hc_use',  year_list = year_list))


t1/60 # 21 min
t2/60 # 17 min
t3/60 # 2 min
t4/60 # 4 min

t5/60/60 # 2.25 hours
