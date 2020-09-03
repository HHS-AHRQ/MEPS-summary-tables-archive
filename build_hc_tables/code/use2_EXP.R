
# meanEXP, medEXP, n_exp ------------------------------------------------------

print("meanEXP, medEXP, n, n_exp") 

events <- c("TOT", "DVT", "RX",  "OBV", "OBD", 
            "OPT", "OPY", "ERT", "IPT", "HHT", "OMA")

sops <- c("EXP", "SLF", "PTR", "MCR", "MCD", "OTZ")

for(row in demo_grps) {
  by_form  <- as.formula(sprintf("~%s", row))
  
  for(ev in events) {
    #ev <- events[i]; use_var <- usevars[i]; ## FIX
    
    for(sp in sops) {
      
      # Only do 2-way tables
      if(row != "ind" & ev != "TOT" & sp != "EXP") next
      
      str_glue("{row}, {ev}, {sp}") %>% print
      
      key <- p(ev, sp)
      formula <- as.formula(str_glue("~{key}"))
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

