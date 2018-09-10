
# Functions for formatting HC tables ------------------------------------------

# Load libraries and source code ---------------------------------------------

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(dplyr)
library(tidyr)
library(stringr)
library(survey)

source("../r/functions.R")
source("dictionaries.R")
source("functions_format.R")


# Event and SOP keys / dictionaries -------------------------------------------

evnt_keys <-
  list("DV"="DVT","ER"="ERT","HH"="HHT","IP"="IPT",
       "OB"="OBV","OM"="OMA","OP"="OPT") %>% stack

evnt_use <-
  list("OBT" = "OBV", "OPD" = "OPY", "OPO" = "OPZ", "IPD" = "IPT") %>% stack


event_dictionary <-
  list("TOT"="Any event",
       "DVT"="Dental visits",
       "RX" ="Prescription medicines",
       "OBV"="Office-based events",
       "OBD"="Physician office visits",
       "OBO"="Non-physician office visits",
       "OPT"="Outpatient events",
       "OPY"="Physician hosp. visits",
       "OPZ"="Non-physician hosp. visits",
       "ERT"="Emergency room visits",
       "IPT"="Inpatient stays",
       "HHT"="Home health events",
       "OMA"="Other medical equipment and services") %>% stack

sp_keys <-
  list("XP" = "EXP", "SF" = "SLF", "PR" = "PTR",
       "MR" = "MCR", "MD" = "MCD", "OZ" = "OTZ") %>% stack

sop_dictionary <-
  list("EXP"="Any source",
       "SLF"="Out of pocket",
       "PTR"="Private",
       "MCR"="Medicare",
       "MCD"="Medicaid",
       "OTZ"="Other") %>% stack

sop_levels <- sop_dictionary$values


delay_dictionary = list(
  "delay_ANY" = "Any care",
  "delay_MD" = "Medical care",
  "delay_DN" = "Dental care",
  "delay_PM" = "Prescription medicines") %>% stack


# Run table formatter ---------------------------------------------------------

adj = data.frame(
  stat = c("totPOP", "totEXP", "totEVT", 
               "meanEVT", "meanEXP", "meanEXP0", "medEXP", 
               "pctEXP", "pctPOP", "avgEVT"),
  
  denom = c(10^3, 10^6, 10^3,         
            1, 1, 1, 1,
            10^(-2), 10^(-2), 1),
  
  digits = c(0, 0, 0,
             0, 0, 0, 0,
             1, 1, 1),
  
  se_digits = c(0, 0, 0,         
                1, 1, 1, 1,        
                2, 2, 2))

adj_use = adj
adj_use[adj$stat == "totEVT",c('denom', 'digits', 'se_digits')] = c(10^6, 0, 1) 

## Format tables 
format_hc_tables(appKey = 'hc_use',  years = year_list, adj = adj_use) 
format_hc_tables(appKey = 'hc_ins',  years = year_list, adj = adj)
format_hc_tables(appKey = 'hc_care', years = year_list, adj = adj)
format_hc_tables(appKey = 'hc_cond', years = year_list, adj = adj)
format_hc_tables(appKey = 'hc_pmed', years = year_list, adj = adj)
