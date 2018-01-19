setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
library(dplyr)

run_r <- function(app) { 
 dir.create(sprintf("%s/r_results",app))
 dir.create(sprintf("%s/sas_results",app))
  
  r_codes = list.files(sprintf("%s/r_codes", app))
  set.seed(20494); r_codes = sample(r_codes); # random reorder
  
  for(i in 1:length(r_codes)) {
    source("../../r/functions.R")
    code_name <- r_codes[i]
    out_name  <- gsub("\\.R", "\\.csv", code_name)
    
    # Skip if output already exists
      if(out_name %in% list.files(sprintf("%s/r_results", app))) next
    
    # Get code and capture results
      code = readSource(sprintf('%s/r_codes/%s', app, code_name))
      if(!grepl('results', code)){
        code <- code %>% gsub("svyby", "results <- svyby", .)
      }
    
    # Run code and output to csv
      run_it = try(run(code))
      if(class(run_it) == "try-error"){
        write.table(i, file = sprintf("%s/r_results/_errors.txt", app), 
                    row.names = F, col.names = F, append = T)
      } else {
        for(j in 1:length(results)) {
          colnames(results[[j]]) = colnames(results[[1]])
        }
        out <- bind_rows(results, .id = 'var')
        write.csv(out, file = sprintf("%s/r_results/%s", app, out_name), row.names = F)
      }
  
    # Remove all objects from code run
      rm(list = ls() %>% pop('app', 'r_codes', 'i', 'errors'))
  }

}


run_r('use')
run_r('ins')
run_r('care')
run_r('cond')
run_r('pmed')

