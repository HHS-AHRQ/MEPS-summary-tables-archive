
# totEVT, meanEVT -------------------------------------------------------------

print("totEVT, meanEVT") 

spX <- c("XPX", "SFX", "PRX", "MRX", "MDX", "OZX")

# By Event type ---------------------------------------------------

print("by Event type...")

for(row in demo_grps) { print(sprintf("  row = %s", row)) 
  
  subdsgn <- subset(EVNTdsgn, XPX >= 0)
  
  by_row     <- as.formula(sprintf("~%s + ind1", row))
  by_event   <- as.formula(sprintf("~%s + event", row))
  by_evt_v2X <- as.formula(sprintf("~%s + event_v2X", row))
  
  res <- list()
  # 
  # res[["totEVT-anyEV"]]  <- svyby(~(XPX >= 0), FUN = svytotal, by = by_row, design = subdsgn)
  # res[["meanEVT-anyEV"]] <- svyby(~XPX,        FUN = svymean,  by = by_row, design = subdsgn)
  
  res[["totEVT-event"]]  <- svyby(~(XPX >= 0), FUN = svytotal, by = by_event, design = subdsgn)
  res[["meanEVT-event"]] <- svyby(~XPX,        FUN = svymean,  by = by_event, design = subdsgn)
  
  res[["totEVT-event_v2X"]]  <- 
    svyby(~(XPX >= 0), FUN = svytotal, by = by_evt_v2X, design = subdsgn)
  
  res[["meanEVT-event_v2X"]] <- 
    svyby(~XPX,        FUN = svymean,  by = by_evt_v2X, design = subdsgn)
  
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