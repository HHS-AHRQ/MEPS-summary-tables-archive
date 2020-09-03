# Create directory and define subgroups, stats --------------------------------

#appKey <- 'hc_cond'
appKey <- "hc_cond_icd10"

tbl_dir <- sprintf("data_tables/%s", appKey)
dir.create(tbl_dir)

row_grps <- rowGrps_R[[appKey]]
col_grps <- colGrps_R[[appKey]]
demo_grps <- col_grps %>% pop("event", "sop")


# Run for specified year(s) ---------------------------------------------------

for(year in year_list[year_list >= 2018]) {
  
  dir.create(sprintf('%s/%s', tbl_dir, year))
  
  yr <- substring(year, 3, 4)
  
  
# Load files, merge, create subgroups, and svydesigns -------------------------
  
  source("code/load_fyc.R", echo = T)     # Load FYC file
  source("code/add_subgrps.R", echo = T)  # Define subgroups
  
  FYCsub <- FYC %>%                       # Keep only needed vars from FYC
    select(one_of(col_grps), DUPERSID, VARSTR, VARPSU, PERWTF)
  
  source("code/load_cond.R", echo = T)    # Load Condition and event files
  source("code/dsgn_cond.R", echo = T)    # Define all survey design objects
  
  
# Loop over col_grps (demographic vars) ---------------------------------------
  
  for(col in demo_grps) { print(col)
    by_form <- as.formula(sprintf("~Condition + %s", col))
    
    res <- list()
    res[["totPOP"]]  <- svyby(~count, by = by_form, FUN = svytotal, design = PERSdsgn)
    res[["totEVT"]]  <- svyby(~count, by = by_form, FUN = svytotal, design = EVNTdsgn)
    res[["totEXP"]]  <- svyby(~XPX,   by = by_form, FUN = svytotal, design = EVNTdsgn)
    res[["meanEXP"]] <- svyby(~XPX,   by = by_form, FUN = svymean,  design = PERSdsgn)
    
    res[["n"]]     <- svyby(~count, by = by_form, FUN = unwtd.count, design = PERSdsgn)
    res[["n_exp"]] <- svyby(~count, by = by_form, FUN = unwtd.count, design = subset(PERSdsgn, XPX > 0))
    
    # Format and output to csv
    for(stat in names(res)) {
      res[[stat]] %>%
        setNames(c("rowLevels", "colLevels", stat, p(stat, "_se"))) %>%
        mutate(rowGrp = "Condition", colGrp = col) %>%
        update.csv(file = sprintf("%s/%s.csv", year, stat), dir = tbl_dir)
    }
    
  } # END for col in demo_grps
  
  
# By event type (design is different) -----------------------------------------
  
  res <- list()
  res[["totPOP"]]  <- svyby(~count, by = ~Condition + event, FUN = svytotal, design = PERSevnt)
  res[["totEVT"]]  <- svyby(~count, by = ~Condition + event, FUN = svytotal, design = EVNTdsgn)
  res[["totEXP"]]  <- svyby(~XPX,   by = ~Condition + event, FUN = svytotal, design = PERSevnt)
  res[["meanEXP"]] <- svyby(~XPX,   by = ~Condition + event, FUN = svymean,  design = PERSevnt)
  
  res[["n"]]     <- svyby(~count, by = ~Condition + event, FUN = unwtd.count, design = PERSevnt)
  res[["n_exp"]] <- svyby(~count, by = ~Condition + event, FUN = unwtd.count, design = subset(PERSevnt, XPX > 0))
  
  # Format and output to csv
  for(stat in names(res)) {
    res[[stat]] %>%
      setNames(c("rowLevels", "colLevels", stat, p(stat, "_se"))) %>%
      mutate(rowGrp = "Condition", colGrp = "event") %>%
      update.csv(file = sprintf("%s/%s.csv", year, stat), dir = tbl_dir)
  }

# By SOP ----------------------------------------------------------------------
  
  sop_form <- as.formula("~XPX + SFX + MRX + MDX + PRX + OZX")
  gt0_form <- as.formula("~(XPX > 0) + (SFX > 0) + (MRX > 0) + (MDX > 0) + (PRX > 0) + (OZX > 0)")
  
  res <- list()
  res[["totPOP"]]  <- svyby(gt0_form, by = ~Condition, FUN = svytotal, design = PERSdsgn)
  res[["totEVT"]]  <- svyby(gt0_form, by = ~Condition, FUN = svytotal, design = EVNTdsgn)
  
  res[["totEXP"]]  <- svyby(sop_form, by = ~Condition, FUN = svytotal, design = EVNTdsgn)
  res[["meanEXP"]] <- svyby(sop_form, by = ~Condition, FUN = svymean,  design = PERSdsgn)
  
  res[["n"]]     <- svyby(~count, by = ~Condition + sop, FUN = unwtd.count, design = subset(ndsgn, XP > 0))
  res[["n_exp"]] <- svyby(~count, by = ~Condition + sop, FUN = unwtd.count, design = subset(ndsgn, XP > 0))
  
  
  # Format and output to csv -- slightly different for n, n_exp
  for(stat in c("n", "n_exp")) {
    res[[stat]] %>%
      setNames(c("rowLevels", "colLevels", stat, p(stat, "_se"))) %>%
      mutate(rowGrp = "Condition", colGrp = "sop") %>%
      update.csv(file = sprintf("%s/%s.csv", year, stat), dir = tbl_dir)
  }
  
  for(stat in c("totPOP", "totEVT", "totEXP", "meanEXP")) {
    res[[stat]] %>% 
      stdize(row = "Condition", stat = stat) %>%
      mutate(rowGrp = "Condition", colGrp = "sop") %>%
      update.csv(file = sprintf("%s/%s.csv", year, stat), dir = tbl_dir)
  }
 
} # END for year in year_list