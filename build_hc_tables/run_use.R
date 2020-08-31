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

# totPOP, pctEXP, totEXP, meanEXP0, n -----------------------------------------
  
  print("totPOP, pctEXP, totEXP, meanEXP0, n") 
  
  # By Event type ---------------------------------------------------
  
    print("By event type...")
    
    use_vars <- c(
      "TOTUSE", "DVTOT", "RXTOT",  "OBTOTV", "OBDRV", "OBOTHV",
      "OPTOTV", "OPDRV", "OPOTHV", "ERTOT",  "IPDIS", "HHTOTD", "OMAEXP")
    
    use_str <- sprintf("(%s > 0)", use_vars) %>% p(collapse = " + ")
    use_form <- as.formula(sprintf("~%s", use_str))
    
    pct_form <- as.formula(
      "~(TOTEXP > 0) + (DVTEXP > 0) + (RXEXP > 0)  + (ERTEXP > 0) + (IPTEXP > 0) + 
        (OBVEXP > 0) + (OBDEXP > 0) + (OBOEXP > 0) + (HHTEXP > 0) + (OMAEXP > 0) +
        (OPTEXP > 0) + (OPYEXP > 0) + (OPZEXP > 0)")
    
    exp_form <- as.formula(
      "~TOTEXP + DVTEXP + RXEXP  + ERTEXP + IPTEXP +
        OBVEXP + OBDEXP + OBOEXP + HHTEXP + OMAEXP +
        OPTEXP + OPYEXP + OPZEXP")
  
    for(row in demo_grps) { print(sprintf("  row = %s", row)) 
      by_form  <- as.formula(sprintf("~%s", row))

      res <- list()
      res[["totPOP"]]   <- svyby(use_form, FUN = svytotal, by = by_form, design = FYCdsgn)
      res[["pctEXP"]]   <- svyby(pct_form, FUN = svymean,  by = by_form, design = FYCdsgn)
      res[["totEXP"]]   <- svyby(exp_form, FUN = svytotal, by = by_form, design = FYCdsgn)
      res[["meanEXP0"]] <- svyby(exp_form, FUN = svymean,  by = by_form, design = FYCdsgn)

      res[["n"]] <- FYC %>% filter(PERWTF > 0) %>% group_by_(row) %>%
        summarise_at(vars(use_vars), function(x) sum(x > 0))
      
      # Output to csv (pull event indicator out of colLevels)
      for(stat in names(res)) { #print(stat)
        res[[stat]] %>% 
          stdize(row = row, stat = stat) %>%
          mutate(
            rowGrp = row, colGrp = "event",
            colLevels = sub("RX", "RX ", colLevels),  
            colLevels = substr(colLevels, 1, 3) %>% trimws) %>%
          update.csv(file = sprintf("%s/%s.csv", year, stat), dir = tbl_dir)
      }
      
    } # END for row in row_grps
        
  # By SOP ----------------------------------------------------------
  
    print("By SOP...")
  
    exp_vars <- 
      c("TOTEXP", "TOTSLF", "TOTPTR",  "TOTMCR", "TOTMCD", "TOTOTZ")
    
    pct_form <- as.formula(
      "~(TOTEXP > 0) + (TOTSLF > 0) + (TOTPTR > 0) + (TOTMCR > 0) + (TOTMCD > 0) + (TOTOTZ > 0)")
    
    exp_form <- as.formula(
      "~TOTEXP + TOTSLF + TOTPTR + TOTMCR + TOTMCD + TOTOTZ")
    
    for(row in demo_grps) {print(sprintf("  row = %s", row)) 
      by_form  <- as.formula(sprintf("~%s", row))
      
      res <- list()
      res[["totPOP"]]   <- svyby(pct_form, FUN = svytotal, by = by_form, design = FYCdsgn)
      res[["pctEXP"]]   <- svyby(pct_form, FUN = svymean,  by = by_form, design = FYCdsgn)
      res[["totEXP"]]   <- svyby(exp_form, FUN = svytotal, by = by_form, design = FYCdsgn)
      res[["meanEXP0"]] <- svyby(exp_form, FUN = svymean,  by = by_form, design = FYCdsgn)
      
      res[["n"]] <- FYC %>% filter(PERWTF > 0) %>% group_by_(row) %>%
        summarise_at(vars(exp_vars), function(x) sum(x > 0))
      
      # Output to csv (pull sop indicator out of colLevels)
      for(stat in names(res)) { #print(stat)
        res[[stat]] %>% 
          stdize(row = row, stat = stat) %>%
          mutate(
            rowGrp = row, colGrp = "sop",
            colLevels = substr(colLevels, 4, 6)) %>%
          update.csv(file = sprintf("%s/%s.csv", year, stat), dir = tbl_dir)
      }
      
    } # END for row in row_grps
    
    
  # Event x SOP ---------------------------------------------------
  
    events <- c("TOT", "DVT", "RX",  "OBV", "OBD", "OBO",
                "OPT", "OPY", "OPZ", "ERT", "IPT", "HHT", "OMA")
    
    sops <- c("EXP", "SLF", "PTR", "MCR", "MCD", "OTZ")
    
    evt_sops <- expand.grid(events, sops) %>% apply(1, p, collapse = "")
    
    plus_str <- evt_sops %>% p(collapse = " + ")
    gt0_str  <- sprintf("(%s > 0)", evt_sops) %>% p(collapse = " + ")
    
    pop_form <- as.formula(sprintf("~%s", gt0_str))
    exp_form <- as.formula(sprintf("~%s", plus_str))
    
    res <- list()
    res[["totPOP"]]   <- svyby(pop_form, FUN = svytotal, by = ~ind, design = FYCdsgn)
    res[["pctEXP"]]   <- svyby(pop_form, FUN = svymean,  by = ~ind, design = FYCdsgn)
    res[["totEXP"]]   <- svyby(exp_form, FUN = svytotal, by = ~ind, design = FYCdsgn)
    res[["meanEXP0"]] <- svyby(exp_form, FUN = svymean,  by = ~ind, design = FYCdsgn)
    
    res[["n"]] <- FYC %>% filter(PERWTF > 0) %>% group_by(ind) %>%
      summarise_at(vars(evt_sops), function(x) sum(x > 0))
    
    # Output to csv (pull event, sop indicators out of colLevels)
    for(stat in names(res)) { print(stat)
      res[[stat]] %>% 
        stdize(row = "ind", stat = stat) %>%
        mutate(                                     
          colLevels = gsub("RX", "RX ", colLevels),
          rowLevels = substr(colLevels, 1, 3) %>% trimws,
          colLevels = substr(colLevels, 4, 6) %>% trimws,
          rowGrp = "event", colGrp = "sop") %>%
        update.csv(file = sprintf("%s/%s.csv", year, stat), dir = tbl_dir)
    }
    
    
# meanEXP, medEXP, n_exp ------------------------------------------------------
  
    print("meanEXP, medEXP, n, n_exp") 
    
    events <- c("TOT", "DVT", "RX",  "OBV", "OBD", "OBO",
                "OPT", "OPY", "OPZ", "ERT", "IPT", "HHT", "OMA")
    
    sops <- c("EXP", "SLF", "PTR", "MCR", "MCD", "OTZ")
    
    for(row in demo_grps) {
      by_form  <- as.formula(sprintf("~%s", row))
      
      for(ev in events) {
        #ev <- events[i]; use_var <- usevars[i]; ## FIX
        
        for(sp in sops) {
          
          # Only do 2-way tables
          if(row != "ind" & ev != "TOT" & sp != "EXP") next
          
          sprintf("%s, %s, %s", row, ev, sp) %>% print
  
          key <- p(ev, sp)
          formula <- as.formula(sprintf("~%s", key))
          subdsgn <- subset(FYCdsgn, FYC[[key]] > 0)
          
          res <- list()
          res[["n_exp"]] <- svyby(~(PERWTF > 0), FUN = unwtd.count, by = by_form, design = subdsgn)
          res[["meanEXP"]] <- svyby(formula, FUN = svymean,     by = by_form, design = subdsgn)
          res[["medEXP"]]  <- svyby(formula, FUN = svyquantile, by = by_form, design = subdsgn,
                                    quantiles=c(0.5), ci=T, method="constant")

          # Output to csv
          for(stat in names(res)) {
            outname <- sprintf("%s/%s.csv", year, stat)
            
            out <- res[[stat]] %>% setNames(c("rowLevels", stat, p(stat, "_se")))
            
            # Will have some duplication to add 'totals' to each cross  
            if(row == "ind") {
              out %>% mutate(
                rowGrp = "event", rowLevels = ev,
                colGrp = "sop",   colLevels = sp) %>%
                update.csv(file = outname, dir = tbl_dir)
            }

            if (ev == "TOT") {
              out %>% 
                mutate(rowGrp = row, colGrp = "sop", colLevels = sp) %>%
                update.csv(file = outname, dir = tbl_dir)
            }
            
            if (sp == "EXP") {
              out %>% 
                mutate(rowGrp = row, colGrp = "event", colLevels = ev) %>%
                update.csv(file = outname, dir = tbl_dir)
            }
            
          } # END for stat in names(res)
          
        } # END for sp in sops
      } # END for ev in events
    } # END for row in demo_grps
    
    
    
# totEVT, meanEVT -------------------------------------------------------------
  
    print("totEVT, meanEVT") 
    
  # By Event type ---------------------------------------------------
    
    print("by Event type...")
    
    for(row in demo_grps) { print(sprintf("  row = %s", row)) 
      
      subdsgn <- subset(EVNTdsgn, XPX >= 0)
      
      by_event   <- as.formula(sprintf("~%s + event", row))
      by_evt_v2X <- as.formula(sprintf("~%s + event_v2X", row))
      
      res <- list()
      res[["totEVT-event"]]  <- svyby(~(XPX >= 0), FUN = svytotal, by = by_event, design = subdsgn)
      res[["meanEVT-event"]] <- svyby(~XPX,        FUN = svymean,  by = by_event, design = subdsgn)
      
      res[["totEVT-event_v2X"]]  <- svyby(~(XPX >= 0), FUN = svytotal, by = by_evt_v2X, design = subdsgn)
      res[["meanEVT-event_v2X"]] <- svyby(~XPX,        FUN = svymean,  by = by_evt_v2X, design = subdsgn)
      
      # Output to csv
      for(rs in names(res)) { 
        stat = str_split(rs, "-")[[1]][1]
        ev   = str_split(rs, "-")[[1]][2]

        res[[rs]] %>% select(-matches("FALSE")) %>%
          setNames(c("rowLevels", "colLevels", stat, p(stat, "_se"))) %>%
          mutate(rowGrp = row, colGrp = ev) %>%
          update.csv(file = sprintf("%s/%s.csv", year, stat), dir = tbl_dir)
      }

    }
    
  # By SOP ----------------------------------------------------------
  
    print("by SOP...")
    
    spX <- c("XPX", "SFX", "PRX", "MRX", "MDX", "OZX")
    
    for(row in demo_grps) { print(sprintf("  row = %s", row)) 
      by_form  <- as.formula(sprintf("~%s", row))

      for(sp in spX) {
        pop_form <- as.formula(sprintf("~(%s > 0)", sp))
        exp_form <- as.formula(sprintf("~%s", sp))
        subdsgn <- subset(EVNTdsgn, EVENTS[[sp]] >= 0)
        
        res <- list()
        res[["totEVT"]]  <- svyby(pop_form, FUN = svytotal, by = by_form, design = subdsgn)
        res[["meanEVT"]] <- svyby(exp_form, FUN = svymean,  by = by_form, design = subdsgn)
        
        # Output to csv (pull event, sop indicators out of colLevels)
        for(stat in names(res)) { 
          res[[stat]] %>% select(-matches("FALSE")) %>%
            setNames(c("rowLevels", stat, p(stat, "_se"))) %>%
            mutate(rowGrp = row, colGrp = "sop", colLevels = sp) %>%
            update.csv(file = sprintf("%s/%s.csv", year, stat), dir = tbl_dir)
        }
      }
    }
    
  # Event x SOP ---------------------------------------------------
    
    spX <- c("XPX", "SFX", "PRX", "MRX", "MDX", "OZX")

    for(sp in spX) {
      pop_form <- as.formula(sprintf("~(%s > 0)", sp))
      exp_form <- as.formula(sprintf("~%s", sp))
      subdsgn <- subset(EVNTdsgn, EVENTS[[sp]] >= 0)
      
      res <- list()
      res[["totEVT-event"]]  <- svyby(pop_form, FUN = svytotal, by = ~event, design = subdsgn)
      res[["meanEVT-event"]] <- svyby(exp_form, FUN = svymean,  by = ~event, design = subdsgn)
      
      res[["totEVT-event_v2X"]]  <- svyby(pop_form, FUN = svytotal, by = ~event_v2X, design = subdsgn)
      res[["meanEVT-event_v2X"]] <- svyby(exp_form, FUN = svymean,  by = ~event_v2X, design = subdsgn)
      
      # Output to csv (pull event, sop indicators out of colLevels)
      for(rs in names(res)) {
        stat = str_split(rs, "-")[[1]][1]
        ev   = str_split(rs, "-")[[1]][2]
        
        res[[rs]] %>% select(-matches("FALSE")) %>%
          setNames(c("rowLevels", stat, p(stat, "_se"))) %>%
          mutate(rowGrp = ev, colGrp = "sop", colLevels = sp) %>%
          select(rowGrp, colGrp, rowLevels, colLevels, colnames(.)) %>%
          update.csv(file = sprintf("%s/%s.csv", year, stat), dir = tbl_dir)
      }
    }
    
    
    
# avgEVT ----------------------------------------------------------------------
    
    print("avgEVT") 
    
    stat <- "avgEVT"
    outname <- sprintf("%s/%s.csv", year, stat)
    
  # By Event type ---------------------------------------------------
    
    print("By event type...")
    
    for(row in demo_grps) {
      by_form  <- as.formula(sprintf("~%s + event", row))
      res <- svyby(~ANY, by = by_form, FUN = svymean, design = EVdsgn)
      res %>% 
        setNames(c("rowLevels", "colLevels", stat, p(stat, "_se"))) %>%
        mutate(rowGrp = row, colGrp = "event") %>%
        update.csv(file = outname, dir = tbl_dir)
    }
    
  # By SOP ----------------------------------------------------------
    
    print("by SOP...")
    
    for(row in demo_grps) {
      by_form  <- as.formula(sprintf("~%s", row))
      res <- svyby(~EXP + SLF + MCR + MCD + PTR + OTZ, FUN = svymean, by = by_form, design = nEVTdsgn)
      res %>%
        stdize(row = row, stat = stat) %>%
        mutate(rowGrp = row, colGrp = "sop") %>%
        update.csv(file = outname, dir = tbl_dir)
    }

    # Event x SOP ---------------------------------------------------
    
    print("Event x SOP...")
    
    res <- svyby(~EXP + SLF + MCR + MCD + PTR + OTZ, by = ~event, FUN = svymean, design = EVdsgn)
    res %>%
      stdize(row = "event", stat = stat) %>%
      mutate(rowGrp = "event", colGrp = "sop") %>%
      update.csv(file = outname, dir = tbl_dir)
  
} # END for year in year_list

