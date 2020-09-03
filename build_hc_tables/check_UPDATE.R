
# Check tables new year vs previous year, for anomalies -------------

# Create directories for log files
  dir.create("update_files/missing", showWarnings = F)
  dir.create("update_files/different", showWarnings = F)

# Initialize log file
  
  sprintf("See update_files/missing for print-outs of sample size (n.csv) for stats that are missing in %s but not in previous 4 years. If sample size in previous years (i.e. coef.y1, coef.y2,...) is small, then missingness is not an issue", hc_year) %>% 
    write(file = log_file)
  
  sprintf("\nThis file lists number and percent of statistics in %s that are different from previous 4 years, when the previous 4 years were not different from each other. High percentages may indicate an error. See udpate_files/different for print-outs", hc_year) %>%
    write(file = log_file, append = T)

  
for(app in apps) { cat("\n", app, "\n"); 
  
  sprintf("\n\nSTARTING APP %s", app) %>% write(file = log_file, append = T)
  
  dir <- sprintf("data_tables/%s",app)
  
  yr.0 <- hc_year
  yr.1 <- hc_year - 1
  yr.2 <- hc_year - 2
  yr.3 <- hc_year - 3
  yr.4 <- hc_year - 4
  
  if(app == "hc_cond_icd10") {
   yr.3 <- yr.4 <- yr.2
  }
  
  yr.0_files <- list.files(sprintf("%s/%s", dir, yr.0))
  yr.1_files <- list.files(sprintf("%s/%s", dir, yr.1))

  # WARN IF NO FILES EXIST
    if(length(yr.0_files) == 0) {
      sprintf("ERROR: No files found in folder for %s app", app) %>% 
        write(file = log_file, append = T)
      next
    }
  
  # WARN IF AVAILABLE FILES ARE DIFFERENT
  
    if(!all(yr.0_files == yr.1_files)) {
      sprintf("WARNING: Not all statistic files are equivalent for %s app, %s vs %s", 
              app, yr.0, yr.1) %>% 
        write(file = log_file, append = T)
    }
  
  csv_files <- yr.0_files[yr.0_files %>% endsWith(".csv")]
  
  for(i in 1:length(csv_files)) {
    
    csv <- csv_files[i]

    stat <- gsub(".csv","",csv, fixed = T)
    se <- paste0(stat,"_se")

    s.0 <- read.csv(sprintf("%s/%s/%s",dir,yr.0,csv), stringsAsFactors = F)
    s.1 <- read.csv(sprintf("%s/%s/%s",dir,yr.1,csv), stringsAsFactors = F)
    s.2 <- read.csv(sprintf("%s/%s/%s",dir,yr.2,csv), stringsAsFactors = F)
    s.3 <- read.csv(sprintf("%s/%s/%s",dir,yr.3,csv), stringsAsFactors = F)
    s.4 <- read.csv(sprintf("%s/%s/%s",dir,yr.4,csv), stringsAsFactors = F)
    
    # for hc_use, make duplicates for row/col
    if(app == "hc_use") {
      s.0 <- bind_rows(s.0, switch_labels(s.0))
      s.1 <- bind_rows(s.1, switch_labels(s.1))
      s.2 <- bind_rows(s.2, switch_labels(s.2))
      s.3 <- bind_rows(s.3, switch_labels(s.3))
      s.4 <- bind_rows(s.4, switch_labels(s.4))
    }
    
    
    by <- c("colGrp", "rowGrp", "colLevels", "rowLevels")
    by <- by[by %in% colnames(s.0)]
    
    s.0 <- s.0 %>% rename_(coef.y0 = stat, se.y0 = se)
    s.1 <- s.1 %>% rename_(coef.y1 = stat, se.y1 = se)
    s.2 <- s.2 %>% rename_(coef.y2 = stat, se.y2 = se)
    s.3 <- s.3 %>% rename_(coef.y3 = stat, se.y3 = se)
    s.4 <- s.4 %>% rename_(coef.y4 = stat, se.y4 = se)
    
    both <- s.0 %>% 
      full_join(s.1, by = by) %>% 
      full_join(s.2, by = by) %>%
      full_join(s.3, by = by) %>%
      full_join(s.4, by = by) 

    # WARN IF COEF IS MISSING IN NEW YEAR BUT NOT PREVIOUS 2 YEARS  
      y0.miss <- both %>% 
        filter(
          is.na(coef.y0) & 
            !is.na(coef.y1) & 
            !is.na(coef.y2) & 
            !is.na(coef.y3) & 
            !is.na(coef.y4)) %>%
        select(-starts_with("se.y"))
      
      # Output n.csv for missing observations
      if(nrow(y0.miss) > 0 & csv == "n.csv") {
        write.table(
          y0.miss, 
          file = sprintf("update_files/missing/%s.csv", app), 
          sep = ",", 
          row.names = F)    
      }
      
      
    both <- both %>%
      mutate(
        p01 = (abs(coef.y0 - coef.y1) / sqrt(se.y0^2 + se.y1^2)) > 1.96,
        p02 = (abs(coef.y0 - coef.y2) / sqrt(se.y0^2 + se.y2^2)) > 1.96,
        p03 = (abs(coef.y0 - coef.y3) / sqrt(se.y0^2 + se.y3^2)) > 1.96,
        p04 = (abs(coef.y0 - coef.y4) / sqrt(se.y0^2 + se.y4^2)) > 1.96,
        
        p12 = (abs(coef.y1 - coef.y2) / sqrt(se.y1^2 + se.y2^2)) > 1.96,
        p13 = (abs(coef.y1 - coef.y3) / sqrt(se.y1^2 + se.y3^2)) > 1.96,
        p14 = (abs(coef.y2 - coef.y4) / sqrt(se.y1^2 + se.y4^2)) > 1.96,
        
        p23 = (abs(coef.y2 - coef.y3) / sqrt(se.y2^2 + se.y3^2)) > 1.96,
        p24 = (abs(coef.y2 - coef.y4) / sqrt(se.y2^2 + se.y4^2)) > 1.96,
        
        p34 = (abs(coef.y3 - coef.y4) / sqrt(se.y3^2 + se.y4^2)) > 1.96,
        
        yr0_diff = (p01 & p02 & p03 & p04),
        others_same = !(p12 | p13 | p14 | p23 | p24 | p34)
      )
    
    
    # WARN IF YR0 IS DIFFERENT FROM PREVIOUS 4 YEARS, BUT PREVIOUS YEARS ARE NOT 
    # DIFFERENT FROM EACH OTHER
      
      discord <- both %>% filter(yr0_diff & others_same) 
      
      n_diff <- nrow(discord)
      pct_diff <- round(nrow(discord) / nrow(both) * 100, 1)
  
      if(pct_diff > 0) {
        sprintf("%s (%s%%) statistics for %s are different from previous 4 years", n_diff, pct_diff, stat) %>%
          write(file = log_file, append = T)
        
        write.table(
          discord, 
          file = sprintf("update_files/different/%s_%s.csv", app, stat), 
          sep = ",", 
          row.names = F)   
      }
  }

}
