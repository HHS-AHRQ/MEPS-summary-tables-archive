# Create directory and define subgroups, stats --------------------------------

appKey <- 'hc_use'

tbl_dir <- sprintf("data_tables/%s", appKey)
dir.create(tbl_dir)

row_grps <- rowGrps_R[[appKey]]
col_grps <- colGrps_R[[appKey]]
demo_grps <- c(row_grps, col_grps) %>% unique %>% 
  pop("event", "event_v2X", "sop")




# demo_grps <- c("ind", "sex") ### !!!! FOR TESTING PURPOSES ONLY !!!





# Run for specified year(s) ---------------------------------------------------

for(year in year_list) {
  
  dir.create(sprintf('%s/%s', tbl_dir, year))
  
  yr <- substring(year, 3, 4)
  
# Load files, merge, create subgroups, and svydesigns -------------------------
  
  source("code/load_fyc.R", echo = T)     # Load FYC file
  source("code/add_subgrps.R", echo = T)  # Define subgroups
  
  FYCsub <- FYC %>%                       # Keep only needed vars from FYC for event merge
    select(one_of(demo_grps), DUPERSID, VARSTR, VARPSU, PERWTF)
  
  source("code/load_use.R", echo = T)    # Load event files
  source("code/dsgn_use.R", echo = T)    # Define all survey design objects
  

# Loop over row_grps and col_grps (demographic vars) --------------------------
  
  for(row in demo_grps) { print(sprintf("row = %s", row))
    
    grp_number <- which(demo_grps == row)
    remaining_grps <- demo_grps[-c(1:grp_number)]
    if(row == "ind") remaining_grps <- demo_grps
    
    for(col in remaining_grps) { 
      
      # Skip if row = col
      row2 = row %>% gsub("_v2X","",.) %>% gsub("_v3X","",.)
      col2 = col %>% gsub("_v2X","",.) %>% gsub("_v3X","",.)
      if(row2 == col2 & row2 != 'ind') next

      print(sprintf("  col = %s", col))
    
      by_form <- as.formula(sprintf("~%s + %s", row, col))
      
      res <- list()
      res[["totPOP"]] <- svyby(~(PERWTF > 0), FUN = svytotal, by = by_form, design = FYCdsgn)
      res[["pctEXP"]] <- svyby(~(TOTEXP > 0), FUN = svymean,  by = by_form, design = FYCdsgn)

       fyc_gt0 <- subset(FYCdsgn, TOTEXP > 0)
      res[["totEXP"]]   <- svyby(~TOTEXP, FUN = svytotal, by = by_form, design = FYCdsgn)
      res[["meanEXP0"]] <- svyby(~TOTEXP, FUN = svymean,  by = by_form, design = FYCdsgn)
      res[["meanEXP"]]  <- svyby(~TOTEXP, FUN = svymean,  by = by_form, design = fyc_gt0)
      res[["medEXP"]]   <- svyby(~TOTEXP, FUN = svyquantile, by = by_form, design = fyc_gt0,
                                 quantiles=c(0.5), ci=T, method="constant")

      evt_gt0 <- subset(EVNTdsgn, XPX >= 0)
      res[["totEVT"]]  <- svyby(~(XPX >= 0), FUN = svytotal, by = by_form, design = evt_gt0)
      res[["meanEVT"]] <- svyby(~XPX,        FUN = svymean,  by = by_form, design = evt_gt0)
      res[["avgEVT"]]  <- svyby(~ANY,        FUN = svymean,  by = by_form, design = nEVTdsgn)

      res[["n"]]     <- svyby(~(PERWTF > 0), FUN = unwtd.count, by = by_form, design = FYCdsgn)
      res[["n_exp"]] <- svyby(~(PERWTF > 0), FUN = unwtd.count, by = by_form, design = fyc_gt0)
      
      # Output to csv
      for(stat in names(res)) { #print(stat)
        out <- res[[stat]] %>% select(-matches("FALSE")) 
        
        if(row == "ind" & col == "ind") {
          out <- out %>% select(-ind) %>%
            mutate(rowLevels = "Total", colLevels = "Total") %>%
            select(rowLevels, colLevels, colnames(.))
        }
        
        out %>%
          setNames(c("rowLevels", "colLevels", stat, p(stat, "_se"))) %>%
          mutate(rowGrp = row, colGrp = col) %>% 
          update.csv(file = sprintf("%s/%s.csv", year, stat), dir = tbl_dir)
      }
      
    } # END for col in demo_grps
  } # END for row in demo_grps
  
  
# By Event type, SOPs ---------------------------------------------------------  
#
#  Splitting up this next section by stat type, since certain stats
#  require subsetting the svydesign object (and hence need loops)

  source("code/use1_POP_EXP0.R", echo = T) # totPOP, pctEXP, totEXP, meanEXP0, n 
  source("code/use2_EXP.R", echo = T)      # meanEXP, medEXP, n_exp
  source("code/use3_EVT.R", echo = T)      # totEVT, meanEVT, avgEVT
    
} # END for year in year_list

