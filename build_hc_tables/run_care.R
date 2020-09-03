# Create directory and define subgroups, stats --------------------------------

appKey <- 'hc_care'

tbl_dir <- sprintf("data_tables/%s", appKey)
dir.create(tbl_dir)

row_grps <- rowGrps_R[[appKey]]
col_grps <- colGrps_R[[appKey]]


# Run for specified year(s) ---------------------------------------------------

for(year in year_list[year_list >= 2002]) {
  
  dir.create(sprintf('%s/%s', tbl_dir, year))
  
  yr <- substring(year, 3, 4)
  yb <- substring(year - 1, 3, 4)
  ya <- substring(year + 1, 3, 4)
  
# Load files, merge, create subgroups, and svydesigns -----------------------
  
  source("code/load_fyc.R", echo = T)     # Load FYC file
  
  # Edit column names for 'year before' and 'year after' vars
  colnames(FYC) <- colnames(FYC) %>% gsub(ya, "ya", .)
  colnames(FYC) <- colnames(FYC) %>% gsub(yb, "yb", .)
  
  source("code/add_subgrps.R", echo = T)  # Define subgroups
  source("code/add_caregrps.R", echo = T) # Add CARE subgroups
  
  source("code/dsgn_care.R", echo = T)    # Define all survey design objects
  
  
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
      
      res[["usc"]] = 
        svyby(~usc, FUN = func, by = by_form, 
              design = subset(FYCdsgn, ACCELI42==1 & HAVEUS42 >= 0 & LOCATN42 >= -1))
    
      difficulty_vars <- c(
        paste0("delay_",  c("ANY", "MD", "DN", "PM")),
        paste0("afford_", c("ANY", "MD", "DN", "PM")),
        paste0("insure_", c("ANY", "MD", "DN", "PM")),
        paste0("other_",  c("ANY", "MD", "DN", "PM"))
      )
      
      if(all(difficulty_vars %in% colnames(FYC))) {
        
        res[["difficulty"]] = 
          svyby(~delay_ANY + delay_MD + delay_DN + delay_PM, 
                FUN = func, by = by_form, design = subset(FYCdsgn, ACCELI42==1))
        
        res[["rsn_ANY"]] = 
          svyby(~afford_ANY + insure_ANY + other_ANY, 
                FUN = func, by = by_form, design = subset(FYCdsgn, ACCELI42==1 & delay_ANY==1))
        
        res[["rsn_MD"]]  = 
          svyby(~afford_MD + insure_MD + other_MD,    
                FUN = func, by = by_form, design = subset(FYCdsgn, ACCELI42==1 & delay_MD==1))
        
        res[["rsn_DN"]]  = 
          svyby(~afford_DN + insure_DN + other_DN,    
                FUN = func, by = by_form, design = subset(FYCdsgn, ACCELI42==1 & delay_DN==1))
        
        res[["rsn_PM"]]  = 
          svyby(~afford_PM + insure_PM + other_PM,    
                FUN = func, by = by_form, design = subset(FYCdsgn, ACCELI42==1 & delay_PM==1))
      }
      
      res[["diab_a1c"]]  = svyby(~diab_a1c,  FUN = func, by = by_form, design = DIABdsgn)
      res[["diab_eye"]]  = svyby(~diab_eye,  FUN = func, by = by_form, design = DIABdsgn)
      res[["diab_flu"]]  = svyby(~diab_flu,  FUN = func, by = by_form, design = DIABdsgn)
      res[["diab_chol"]] = svyby(~diab_chol, FUN = func, by = by_form, design = DIABdsgn)
      res[["diab_foot"]] = svyby(~diab_foot, FUN = func, by = by_form, design = DIABdsgn)
      
      qual_vars <- c("routine", "illness", "time", "listen", "rating", "respect", "explain")
      
      qual_vars_adult <- paste0("adult_", qual_vars)
      qual_vars_child <- paste0("child_", qual_vars)
      
      
      # Adult quality of care variables

      if("adult_nosmok" %in% colnames(FYC)) {
      res[["adult_nosmok"]]  = 
        svyby(~adult_nosmok,  FUN = func, by = by_form, 
              design = subset(SAQdsgn, ADSMOK42==1))
      }
      
      if(all(qual_vars_adult %in% colnames(FYC))) {
        res[["adult_routine"]] = 
          svyby(~adult_routine, FUN = func, by = by_form, 
                design = subset(SAQdsgn, ADRTCR42==1 & AGELAST >= 18))
    
        res[["adult_illness"]] = 
          svyby(~adult_illness, FUN = func, by = by_form, 
                design = subset(SAQdsgn, ADILCR42==1 & AGELAST >= 18))
        
        adult_dsgn <- subset(SAQdsgn, ADAPPT42 >= 1 & AGELAST >= 18)
        res[["adult_time"]]    = svyby(~adult_time,    FUN = func, by = by_form, design = adult_dsgn)
        res[["adult_listen"]]  = svyby(~adult_listen,  FUN = func, by = by_form, design = adult_dsgn)
        res[["adult_rating"]]  = svyby(~adult_rating,  FUN = func, by = by_form, design = adult_dsgn)
        res[["adult_respect"]] = svyby(~adult_respect, FUN = func, by = by_form, design = adult_dsgn)
        res[["adult_explain"]] = svyby(~adult_explain, FUN = func, by = by_form, design = adult_dsgn)
      }
      
      # Child quality of care variables (only odd years starting 2017, except child_dental)
      
      res[["child_dental"]]  = 
        svyby(~child_dental,  FUN = func, by = by_form, 
              design = subset(FYCdsgn, child_2to17==1))
      
      if(all(qual_vars_child %in% colnames(FYC))) {
        res[["child_routine"]] = 
          svyby(~child_routine, FUN = func, by = by_form, 
                design = subset(FYCdsgn, CHRTCR42==1 & AGELAST < 18))
        
        res[["child_illness"]] = 
          svyby(~child_illness, FUN = func, by = by_form, 
                design = subset(FYCdsgn, CHILCR42==1 & AGELAST < 18))
        
        child_dsgn <- subset(FYCdsgn, CHAPPT42 >= 1 & AGELAST < 18)
        res[["child_time"]]    = svyby(~child_time,    FUN = func, by = by_form, design = child_dsgn)
        res[["child_listen"]]  = svyby(~child_listen,  FUN = func, by = by_form, design = child_dsgn)
        res[["child_rating"]]  = svyby(~child_rating,  FUN = func, by = by_form, design = child_dsgn)
        res[["child_respect"]] = svyby(~child_respect, FUN = func, by = by_form, design = child_dsgn)
        res[["child_explain"]] = svyby(~child_explain, FUN = func, by = by_form, design = child_dsgn)
      }
      
      # Format and output to csv ----------------------------------------------
      stat_se = p(stat, "_se")
      
      for(rs in names(res)) {
     
        if(stat == "n") {
          out <- res[[rs]] %>% setNames(c("rowLevels", stat, stat_se))
          
        } else { # re-group for totPOP and pctPOP
          out <- res[[rs]] %>% 
            stdize(row = row, stat = stat) %>%
            mutate(colLevels = sub(rs,"",colLevels))
        }
        
        out %>% mutate(rowGrp = row, colGrp = rs) %>%
          update.csv(file = sprintf("%s/%s.csv", year, stat), dir = tbl_dir)
      }

    } # END for stat in names(stat_FUNS)
  } # END for row in row_grps
  
} # END for year in year_list