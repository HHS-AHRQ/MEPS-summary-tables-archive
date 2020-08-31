# Create directory and define subgroups, stats --------------------------------

appKey <- 'hc_ins'

tbl_dir <- sprintf("data_tables/%s", appKey)
dir.create(tbl_dir)

row_grps <- rowGrps_R[[appKey]]
col_grps <- colGrps_R[[appKey]]

# Run for specified year(s) ---------------------------------------------------

for(year in year_list) {
  
  dir.create(sprintf('%s/%s', tbl_dir, year))
  
  yr <- substring(year, 3, 4)
  
# Load files, merge, create subgroups, and svydesigns -----------------------
  
  source("code/load_fyc.R", echo = T)     # Load FYC file
  source("code/add_subgrps.R", echo = T)  # Define subgroups
  
  FYCdsgn <- svydesign(
    id = ~VARPSU,
    strata = ~VARSTR,
    weights = ~PERWTF,
    data = FYC,
    nest = TRUE)

# Loop over row_grps (demographic vars) and stats -----------------------------
  
  stat_FUNS <- list(
    totPOP = svytotal, 
    pctPOP = svymean, 
    n = unwtd.count)
  
  for(row in row_grps) { print(row)
    for(stat in names(stat_FUNS)) { print(stat)
      
      by_form <- as.formula(sprintf("~%s", row))
      func <- stat_FUNS[[stat]]
      
      res <- list()
      res[["insurance"]] = svyby(~insurance,     FUN = func, by = by_form, design = FYCdsgn)
      res[["ins_lt65"]]  = svyby(~insurance_v2X, FUN = func, by = by_form, design = subset(FYCdsgn, AGELAST < 65))
      res[["ins_ge65"]]  = svyby(~insurance_v2X, FUN = func, by = by_form, design = subset(FYCdsgn, AGELAST >= 65))

      # Format and output to csv ----------------------------------------------
      stat_se = p(stat, "_se")
      
      for(rs in names(res)) {
        
        if(stat == "n") {
          out <- res[[rs]] %>% setNames(c("rowLevels", stat, stat_se))
          
        } else {
          out <- res[[rs]] %>% 
            stdize(row = row, stat = stat) %>%
            mutate(
              colLevels = sub("insurance","",colLevels),
              colLevels = sub("_v2X","",colLevels)
            )
        }

        out %>% mutate(rowGrp = row, colGrp = rs) %>%
          update.csv(file = sprintf("%s/%s.csv", year, stat), dir = tbl_dir)
      }
      
    } # END for stat in names(stat_FUNS)
  } # END for row in row_grps
  
} # END for year in year_list









