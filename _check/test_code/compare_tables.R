## Compare tables generated from tables_run.R with those based on 
## code output from web app (extracted via rselenium)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
library(dplyr)
library(tidyr)

source("../../r/functions.R")
source("../../r/dictionaries.R")

# Functions -------------------------------------------------------------------

addVar <- function(df, varname, value) {
  if(!varname %in% colnames(df)) {
    df[,varname] = value
  }
  return(df)
}

cleanup <- function(text, remove_words = NULL) {
  
  for(word in remove_words) {
    text <- gsub(word, '', text)
  }
  
  text %>% 
    gsub('_v2X', '', .) %>%
    gsub('0FALSE','',.) %>%
    gsub('0TRUE','',.) %>%
    gsub("[[:punct:]]","",.) %>%
    gsub(" ","",.) %>%
    tolower
}

get_context <- function(name) {
  result_context <- strsplit(name, "_")[[1]]
  stat <- result_context[1]
  row <- result_context[2]
  
  if(length(result_context) == 5) {
    col <- paste0(result_context[3],"_",result_context[4])
    year <- result_context[5]
  } else {
    col  <- result_context[3]
    year <- result_context[4]
  }
  year <- year %>% gsub(".csv", "", .)
  yr <- substring(year, 3, 4)
  
  if(row == col) row <- 'ind'
  if(row == 'sop') {
    row = col
    col = 'sop'
  }
  grps <- c(row, col)
  return(list(stat = stat, row = row, col = col, year = year, yr = yr, grps = grps))
}

rm_year <- function(df, yr) {
  if('rowLevels' %in% colnames(df)) {
    df <- df %>% mutate(rowLevels = gsub(paste0(yr,"X"),"",rowLevels),
                        rowLevels = gsub(yr,"",rowLevels))
  }
  if('colLevels' %in% colnames(df)) {
    df <- df %>% mutate(colLevels = gsub(paste0(yr,"X"),"",colLevels),
                        colLevels = gsub(yr,"",colLevels))
  }
  return(df)
}

summaryNA <- function(vec) {
  summ = summary(vec)
  if(!any(is.na(vec)))
    return( c(summ, "NA's" = 0))
  return(summ)
}

wrangle_data_table <- function(df, app, info, lang) {
  grps <- c(info$row, info$col)
  is_evt <- 'event' %in% grps
  is_sop <- 'sop' %in% grps
  
  if(app == 'use') {
    df <- bind_rows(df, switch_labels(df)) 
    if(is_evt & is_sop & !info$stat %in% c("meanEVT", "totEVT", "avgEVT")) {
      df <- df %>%
        mutate(
          cmbLevels = paste0(rowLevels, colLevels),
          rowLevels = cmbLevels,
          colLevels = cmbLevels) %>%
        select(-cmbLevels)
    }
  }
  
  df <- df %>%
    filter(rowGrp == info$row, colGrp == info$col) %>%
    select(-rowGrp, -colGrp) %>% 
    gather(key, value, -rowLevels, -colLevels) %>%
    mutate(key = gsub(info$stat, '', key)) 
  
  if(lang == "SAS") {
   df <- df %>%
    mutate( 
      colLevels = as.character(colLevels),
      colLevels = replace(colLevels, startsWith(colLevels,"afford"), "Couldn't afford"),
      colLevels = replace(colLevels, startsWith(colLevels,"insure"), "Insurance related"),
      colLevels = replace(colLevels, startsWith(colLevels,"other"), "Other") )
  }
  return(df)
}

use_edits <- function(df, info, lang) {
  vname <- ifelse(lang == "R", 'var', 'varname')
  grps <- c(info$row, info$col)
  is_evt <- 'event' %in% grps
  is_sop <- 'sop' %in% grps

  if(is_evt & !('event' %in% colnames(df))) df$event = df[,vname]
  if(is_sop & info$stat != 'avgEVT') df$sop = df[,vname]     
  if(is_sop & lang == "SAS") df$sop = df[,vname]    
  if(is_evt & is_sop)  df <- df %>% select(-ind)
  if(is_evt & !is_sop) df <- df %>% mutate(event = gsub("EXP", "", event))
  if('sop' %in% colnames(df) & !is_evt) df <- df %>% mutate(sop = gsub("TOT", "", sop))
  
  if(info$stat == 'totPOP' & is_evt & !is_sop) {
    df <- df %>%
      mutate(event = substring(event, 1, 3),
             event = replace(event, event == 'RXT', 'RX'))
  }
    
  return(df)
}

combine_tables <- function(df1, df2, byvars) {
  full_join(web_table, data_table, by = byvars) %>%
    mutate(diff = value.x - value.y) %>%
    mutate(diff = round(diff, 5)) %>%
    mutate(diff = ifelse(value.x > 1E10 & value.y > 1E10, round(diff, -5), diff)) %>%
    mutate(diff = ifelse(value.x > 2000 & value.y > 2000, round(diff), diff)) %>%
    filter(rowLevels != "Missing" & colLevels != "Missing")
}

# Get app directories----------------------------------------------------------

# 
# app <- 'use'
# app <- 'ins'
# app <- 'care'
# app <- 'pmed'
# app <- 'cond'

apps <- c('use', 'ins', 'care', 'pmed', 'cond') 

 
# R ---------------------------------------------------------------------------

R_MISSING <- R_ERRORS <- R_RESULTS <- list()
for(app in apps) {  
  tables_dir  <- sprintf("../tables/%s/", app)
  web_r_dir <- sprintf("%s/r_results/", app)
  r_results <- list.files(web_r_dir)
  r_codes <- list.files(sprintf("%s/r_codes", app))
  
  # Check that number of 'test codes' = number of results tables
    n_results <- length(r_results) ; res <- r_results %>% gsub("\\.csv", "", .);
    n_codes   <- length(r_codes)   ; cds <- r_codes   %>% gsub("\\.R", "", .);
    n_results == n_codes
    
    R_MISSING[[app]] = cds[!cds %in% res] 
    
  test_results <- errors <- NULL
  for(i in 1:n_results) { print(i)
    
    if('joint' %in% ls()) rm(joint)
    
    # Get stat, row, col, year, from table results name
      result <- r_results[i]
      info <- get_context(result)
      is_evt <- 'event' %in% info$grps
      is_sop <- 'sop' %in% info$grps

    # Load and wrangle data table
      data_table <- read.csv(sprintf("../%s/%s/%s.csv", tables_dir, info$year, info$stat), 
                             stringsAsFactors = F) 
      data_table <- wrangle_data_table(data_table, app, info, lang = "R")
      
    # Load and wrangle web-based table
      web_table <- read.csv(paste0(web_r_dir, result), stringsAsFactors = F)
      web_table <- web_table[,!grepl("FALSE", colnames(web_table))]
      if(app == 'use') web_table <- use_edits(web_table, info, lang = "R")
      
      rowcol <- all(info$grps %in% colnames(web_table))
      if(rowcol) {
        byvars <- c("rowLevels", 'colLevels', 'match')
        web_table <- web_table %>%
          mutate_(rowLevels = info$row, colLevels = info$col) %>%
          rm_year(info$yr) %>%
          select(-var, -one_of(info$grps)) %>%
          gather(key, value, -rowLevels, -colLevels) %>%
          mutate(colLevels = replace(colLevels, colLevels == 1, 'Total'),
                 rowLevels = replace(rowLevels, rowLevels == 1, 'Total')) %>%
          filter(key != 'ind')

      } else{
        byvars <- c("rowLevels", "match")
        web_table <- web_table %>%
          mutate_(rowLevels = info$row) %>%
          rm_year(info$yr) %>%
          select(-var, -one_of(info$row)) %>%
          gather(key, value, -rowLevels) %>%
          mutate(rowLevels = replace(rowLevels, rowLevels == 1, 'Total')) %>%
          filter(key != 'ind')
      }
      
    # Combine web results and data table
      special_use = (app == 'use' & is_evt & is_sop & info$stat %in% c('meanEXP'))
      
      if(rowcol | app == "pmed" | special_use) {  
        web_table  <- web_table  %>% mutate(match = ifelse(grepl('se', key), 'se', 'coef'))
        data_table <- data_table %>% mutate(match = ifelse(grepl('se', key), 'se', 'coef'))
      } else {
        web_table  <- web_table %>% mutate(match = cleanup(key, c(info$col, 'insurance')))
        data_table <- data_table %>% mutate(match = cleanup(paste0(key, colLevels)))
      }
      
      joint <- combine_tables(web_table, data_table, by = byvars)
      
      # Check different rows
      look = joint %>% 
        filter(is.na(diff) & rowLevels != "Missing" & colLevels != "Missing") %>%
        filter(!(is.na(value.x) & is.na(value.y))) %>%
        filter(!(is.na(value.x) & value.y == 0)) 
      if(nrow(look) > 0) {
        errors = c(errors, i)
        print(look %>% head)
      }
      
      # check out diffs
      # print(joint %>% filter(diff != 0))
      
      # Print and save results
      print(summaryNA(joint$diff))
      test_results = rbind(test_results, c(i, summaryNA(joint$diff)))
  }
  

  # diffs = which(test_results[,'Max.'] != 0 | test_results[,'Min.'] != 0) 
  # r_results[diffs]
  # r_results[errors]
  
  R_ERRORS[[app]] = errors
  R_RESULTS[[app]] = apply(test_results, 2, round, digits = 4)  
}

print(R_MISSING)
print(R_ERRORS)
print(R_RESULTS)

# SAS ---------------------------------------------------------------------------
 

SAS_MISSING <- SAS_ERRORS <- SAS_RESULTS <- SAS_DIFFS <- list()
for(app in apps) {
  
  tables_dir  <- sprintf("../tables/%s/", app)
  web_sas_dir <- sprintf("%s/sas_results/", app)
  sas_results <- list.files(web_sas_dir)
  sas_codes <- list.files(sprintf("%s/sas_codes", app))
  
  # Check that number of 'test codes' = number of results tables
    n_results <- length(sas_results) ; res <- sas_results %>% gsub(".csv", "", .);
    n_codes   <- length(sas_codes)   ; cds <- sas_codes   %>% gsub(".sas", "", .);
    n_results == n_codes
    
    SAS_MISSING[[app]] = cds[!cds %in% res] 

  app_diffs <- list()
  test_results <- errors <- NULL
  for(i in 1:n_results) { print(i)
   
     if('joint' %in% ls()) rm(joint)
    
    # Get stat, row, col, year, from table results name
    result <- sas_results[i]
    info <- get_context(result)
    is_evt <- 'event' %in% info$grps
    is_sop <- 'sop' %in% info$grps
    
    
    # Load and wrangle data table
    data_table <- read.csv(sprintf("../%s/%s/%s.csv", tables_dir, info$year, info$stat),
                           stringsAsFactors = F) 
    data_table <- wrangle_data_table(data_table, app, info, lang = "SAS") %>%
      rm_year(info$yr)
    
    # Load and wrangle web-based table
    web_table <- read.csv(paste0(web_sas_dir, result), stringsAsFactors = F)
    colnames(web_table) = tolower(colnames(web_table))
    
    if(app == 'use') web_table <- use_edits(web_table, info, lang = "SAS")
    
    rowLev = info$row %>% tolower
    colLev = info$col %>% tolower
    if(colLev %in% c("ins_ge65", "ins_lt65")) colLev <- "insurance_v2x"
    
    if(colLev %>% startsWith('rsn')) {
      suffix = substring(colLev,5)
      web_table <- web_table %>%
        mutate_(afford = paste0("afford_", suffix), 
                insure = paste0("insure_", suffix),
                other  = paste0("other_", suffix)) %>%
        mutate(rsn = paste0(afford, insure, other)) %>%
        filter(rsn != '0')
      web_table[,colLev] = web_table$rsn
    }
    
    if(colLev == "difficulty") {
      web_table <- web_table %>%
        mutate(difficulty = case_when(
          delay_any == "Difficulty accessing care" ~ "delay_ANY",
          delay_md == "Difficulty accessing care" ~ "delay_MD",
          delay_dn == "Difficulty accessing care" ~ "delay_DN",
          delay_pm == "Difficulty accessing care" ~ "delay_PM"))
    }
    
    if(rowLev == "tc1name") rowLev <- "tc1"
    
    select_vars <- 
      switch(info$stat,
             "totEVT" = c("sum", "stddev"),
             "totEXP" = c("sum", "stddev"),
             "totPOP" = c("sum", "stddev"),
             "pctPOP" = c("rowpercent", "rowstderr"),
             "medEXP" = c("estimate", "stderr"),
             c("mean", "stderr"))
    
    if(app %in% c('ins', 'care') & info$stat == "totPOP") {
      select_vars = c("wgtfreq", "stddev")
    }
    
    if(app == 'cond' & is_sop) {
      web_table$sop = web_table$varname
    }
    
    web_table <- web_table %>% 
      addVar('ind', 'Total') %>%
      addVar('domain', 1) %>%
      mutate_(rowLevels = rowLev, colLevels = colLev) %>%
      rm_year(info$yr) %>%
      filter(domain == 1, rowLevels != '', colLevels != '') %>%
      select(rowLevels, colLevels, one_of(select_vars)) %>%
      gather(key, value, -rowLevels, -colLevels) %>%
      mutate(value = as.numeric(value)) %>%
      filter(!is.na(value)) %>%
      add_labels(evnt_keys)
    
    if(info$stat == "pctPOP") {
      web_table <- web_table %>% mutate(value = value / 100)
    }
    
    # Combine tables
    
    if(app == 'pmed'){
      data_table$rowLevels = tolower(data_table$rowLevels)
      web_table$rowLevels  = tolower(web_table$rowLevels)
    }
    
    web_table  <- web_table  %>% mutate(match = ifelse(grepl('std', key), 'se', 'coef'))
    data_table <- data_table %>% mutate(match = ifelse(grepl('_se', key), 'se', 'coef'))
    joint <- combine_tables(web_table, data_table, 
                            byvars = c("rowLevels", "colLevels", "match"))

    # Check different rows
      look = joint %>% 
        filter(is.na(diff) & rowLevels != "Missing" & colLevels != "Missing") %>%
        filter(rowLevels != '-9') %>% # for PMEDs
        filter(rowLevels != '-8') %>% # for COND
        filter(rowLevels != 'Other') %>% # for COND
        filter(!(is.na(value.x) & is.na(value.y))) %>%
        filter(!(is.na(value.x) & value.y == 0)) 
      if(nrow(look) > 0) {
        errors = c(errors, i)
        print(look %>% head)
      }

      # check out diffs
      diffs <- joint %>% filter(diff != 0) 
      if(nrow(diffs) != 0) {
        print(diffs %>% head)
        app_diffs[[result]] = diffs
      }
    # Print and save results
      #print(summaryNA(joint$diff))
      test_results = rbind(test_results, c(i, summaryNA(joint$diff)))
  }

  # diffs = which(test_results[,'Max.'] != 0 | test_results[,'Min.'] != 0) 
  # sas_results[diffs]
  
  SAS_DIFFS[[app]] = app_diffs
  SAS_ERRORS[[app]] = errors
  SAS_RESULTS[[app]] = apply(test_results, 2, round, digits = 4)  
  
} # end for app in apps

print(SAS_MISSING)
print(SAS_ERRORS)
print(SAS_RESULTS)
print(SAS_DIFFS)

# Checking SAS results differences

# for Use, medians are different between R and SAS
  use_diffs <- SAS_DIFFS[['use']]
  names(use_diffs)
  
  for(i in 1:length(use_diffs)) {
    print(names(use_diffs)[i])
    dd = use_diffs[[i]]
    dd %>% arrange(-abs(diff)) %>% head(10) %>% print
  }


# for Cond, SEs are different due to lonely PSU errors in SAS
  cond_diffs <- SAS_DIFFS[['cond']]
  
  for(i in 1:length(cond_diffs)) {
    print(names(cond_diffs)[i])
    dd = cond_diffs[[i]]
    #dd %>% filter(match == 'coef') %>% print
    dd %>% arrange(-abs(diff)) %>% head(10) %>% print
  }

