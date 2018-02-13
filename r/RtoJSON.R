setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(dplyr)
library(tidyr)
library(stringr)
library(jsonlite)
library(MEPS)
library(RColorBrewer)

source("functions.R")
source("dictionaries.R")
source("codes.R")
source("notes.R")

# Color brewer palette --------------------------------------------------------
# 
# vec = brewer.pal(12, "Paired") %>% col2rgb %>% 
#   apply(2, function(x) paste0(x, collapse=",")) %>%
#   matrix(nrow = 2) 
# 
# c(vec[2,],vec[1,]) %>%
#   paste0(collapse = "','") %>% 
#   sprintf("'%s'",.)
# 

write_data = TRUE
write_code = TRUE

# Adjustment (can change for specific apps) -----------------------------------

adj = data.frame(
  stat     = c("totPOP", "totEXP", "totEVT", "meanEVT", "meanEXP", "meanEXP0", "medEXP", "pctEXP", "pctPOP", "avgEVT"),
  denom    = c(    10^3,     10^6,     10^3,         1,         1,         1,         1,  10^(-2),  10^(-2),        1),
  digits    = c(      0,        0,        0,         0,         0,         0,         0,        1,       1,         1),
  se_digits = c(      0,        0,        0,         1,         1,         1,         1,        2,       2,         2))

adj_use = adj
adj_use[adj$stat == "totEVT",c('denom', 'digits', 'se_digits')] = c(10^6, 0, 1) 


# Use, expenditures, and population -------------------------------------------
years = 1996:2015
if(write_data) data_toJSON(appKey = 'use', years = years, adj = adj_use, pivot = F)
if(write_code) code_toJSON(appKey = 'use', years = years)

# Health insurance ------------------------------------------------------------
years = 1996:2015
if(write_data) data_toJSON(appKey = 'ins', years = years, adj = adj, pivot = F)
if(write_code) code_toJSON(appKey = 'ins', years = years)

# Accessibility and quality of care -------------------------------------------
years = 2002:2015
if(write_data) data_toJSON(appKey = 'care', years = years , adj = adj, pivot = F)
if(write_code) code_toJSON(appKey = 'care', years = years)

# Medical conditions ----------------------------------------------------------
years = 1996:2015
if(write_data) data_toJSON(appKey = 'cond', years = years, adj = adj, pivot = T)
if(write_code) code_toJSON(appKey = 'cond', years = years)

# Prescribed Drugs ------------------------------------------------------------
years = 1996:2015
if(write_data) data_toJSON(appKey = 'pmed', years = years, adj = adj, pivot = T)
if(write_code) code_toJSON(appKey = 'pmed', years = years)

