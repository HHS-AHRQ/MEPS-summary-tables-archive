library(testthat)
library(tidyverse)


setwd("C:/Users/emily.mitchell/Desktop/GitHub/hhs_ahrq/MEPS-tables/build_hc_tables")

app <- "hc_care"

apps <- c("hc_care", "hc_cond", "hc_cond_icd10", "hc_ins", "hc_pmed", "hc_use")


year <- 2017

for(app in apps) { cat(app,"...\n")
 
  
     
  orig_folder <- str_glue("data_tables - Copy/{app}/{year}")
 # orig_folder <- str_glue("data_tables/{app}/{year} - orig")
  new_folder  <- str_glue("data_tables/{app}/{year}")
  
  orig_files <- list.files(orig_folder)
  new_files  <- list.files(new_folder)
  
  orig_csvs <- orig_files[orig_files %>% endsWith(".csv")]
  new_csvs  <- new_files[new_files %>% endsWith(".csv")]
  
  compare(orig_csvs, new_csvs) %>% print
  
  for(file in orig_csvs) { print(file)
    
      #rm(list = c("orig_file", "orig_dup", "new_file", "new_dup", "diff1", "diff2"))
    
      orig_file <- orig_dup <- read.csv(str_glue("{orig_folder}/{file}"))
      new_file  <- new_dup <- read.csv(str_glue("{new_folder}/{file}"))
      
      
      if(app %in% c("hc_use")) {
        
        orig_dup <- bind_rows(orig_file, switch_labels(orig_file))
        new_dup  <- bind_rows(new_file, switch_labels(new_file))
        
        new_dup <- new_dup %>%
          filter(
            !colLevels %in% c("OBO", "OPZ"),
            !rowLevels %in% c("OBO", "OPZ")) %>%
          add_labels(sp_keys)
    
        orig_dup <- orig_dup %>%
          filter(
            !colLevels %in% c("OBO", "OPZ"),
            !rowLevels %in% c("OBO", "OPZ")) %>%
          add_labels(sp_keys)
        
        if(file == "n.csv") {
          new_dup$n_se = 0
          new_dup <- new_dup %>% filter(n > 0)
        }
      }
  
      same <- all_equal(orig_dup, new_dup) 
      
      # print(same)
     
      if(same != TRUE) {
        diff1 <- setdiff(orig_dup, new_dup); diff1 %>% head %>% print;
        diff2 <- setdiff(new_dup, orig_dup); diff2 %>% head %>% print;
        
        #diff1 %>% as_tibble() %>% count(rowGrp, colGrp) %>% print(n = 100)
        #diff2 %>% as_tibble() %>% count(colGrp, rowGrp) %>% print(n = 100)
      }
      
  }
  
  chk <- full_join(orig_dup, new_dup, 
                   by = c("rowGrp", "colGrp", "rowLevels", "colLevels"))
  
  
  # chk %>% filter(colLevels == "Separated", rowGrp == "event")
  # chk %>% filter(round(medEXP_se.x,1) != round(medEXP_se.y,1)) #%>% head(20)
  # chk %>% filter(medEXP.x != medEXP.y) %>% head(20) # 0 rows
  # chk %>% filter(is.na(medEXP.x) | is.na(medEXP.y))
  # 
  # orig_dup %>% filter(rowGrp == "ind", colGrp == "ind")
  # new_dup %>% filter(rowGrp == "ind", colGrp == "ind")

}


# Formatted files ----------------------------------------------------------
setwd("C:/Users/emily.mitchell/Desktop/GitHub/hhs_ahrq/MEPS-tables/build_hc_tables")

year <- 2017
app <- "hc_use"

# The only difference should be totPOP-'Any Event' for hc_use
# previously, was accidentally counting all people, not just those with an event


for(app in apps) { cat("\n", app,"...\n")
  
  for(year in c(1996:2017)) { print(year)
    
    if(app == "hc_care" & year < 2002) next
    if(app == "hc_cond" & year > 2015) next
    if(app == "hc_cond_icd10" & year < 2016) next
    
    rm(orig_file)
    rm(new_file)
    
    orig_file <- read.csv(str_glue("../formatted_tables/_archive/{app} - Copy/DY{year}.csv"))
    new_file  <- read.csv(str_glue("../formatted_tables/{app}/DY{year}.csv"))
 
    byvars <- c("stat_group", "stat_var", "stat_label", "caption",
                "row_group", "row_var", "row_label", "rowLevels", 
                "col_group", "col_var", "col_label", "colLevels")
    
    jvars <- byvars[byvars %in% colnames(orig_file)]
    
    chk <- full_join(orig_file, new_file, by = jvars)
    
    orig_miss <- chk %>% filter(is.na(coef.x), !is.na(coef.y)) 
    new_miss  <- chk %>% filter(is.na(coef.y), !is.na(coef.x)) 
    new_diff  <- chk %>% filter(coef.x != coef.y | se.x != se.y)
    
    if(nrow(orig_miss) > 0) {
      print(orig_miss %>% head)
    } 
    if(nrow(new_miss) > 0) {
      print(new_miss %>% head)
    } 
    if(nrow(new_diff) > 0) {
      print(new_diff %>% count(stat_var, colLevels) )
    } 
    # 
    # orig_miss %>% head %>% print
    # new_miss  %>% head %>% print
    # new_diff  %>% head %>% print
    
    # new_miss %>% count(stat_var) 
    # new_miss %>% count(stat_var, row_var, col_var) %>% print(n = 100)
    # View(new_miss)
    # 
    # new_diff_coef %>% count(stat_var, colLevels)
    # new_diff_se %>% count(stat_var)
    # View(new_diff)


  }
}

