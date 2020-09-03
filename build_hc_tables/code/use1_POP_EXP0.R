
# totPOP, pctEXP, totEXP, meanEXP0, n -----------------------------------------

print("totPOP, pctEXP, totEXP, meanEXP0, n") 

# By Event type ---------------------------------------------------

print("By event type...")

use_vars <- c(
  "TOTUSE", "DVTOT", "RXTOT",  "OBTOTV", "OBDRV", 
  "OPTOTV", "OPDRV", "ERTOT",  "IPDIS", "HHTOTD", "OMAEXP")

use_str <- sprintf("(%s > 0)", use_vars) %>% p(collapse = " + ")
use_form <- as.formula(sprintf("~%s", use_str))

pct_form <- as.formula(
  "~(TOTEXP > 0) + (DVTEXP > 0) + (RXEXP > 0)  + (ERTEXP > 0) + (IPTEXP > 0) + 
  (OBVEXP > 0) + (OBDEXP > 0) + (HHTEXP > 0) + (OMAEXP > 0) +
  (OPTEXP > 0) + (OPYEXP > 0)")

exp_form <- as.formula(
  "~TOTEXP + DVTEXP + RXEXP  + ERTEXP + IPTEXP +
  OBVEXP + OBDEXP + HHTEXP + OMAEXP +
  OPTEXP + OPYEXP")

for(row in demo_grps) { print(sprintf("  row = %s", row)) 
  by_form  <- as.formula(sprintf("~%s", row))
  
  res <- list()
  res[["totPOP"]]   <- svyby(use_form, FUN = svytotal, by = by_form, design = FYCdsgn)
  res[["pctEXP"]]   <- svyby(pct_form, FUN = svymean,  by = by_form, design = FYCdsgn)
  res[["totEXP"]]   <- svyby(exp_form, FUN = svytotal, by = by_form, design = FYCdsgn)
  res[["meanEXP0"]] <- svyby(exp_form, FUN = svymean,  by = by_form, design = FYCdsgn)
  
  res[["n"]] <- FYC %>% filter(PERWTF > 0) %>% group_by_at(row) %>%
    summarise_at(use_vars, function(x) sum(x > 0))
  
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
  
  res[["n"]] <- FYC %>% filter(PERWTF > 0) %>% group_by_at(row) %>%
    summarise_at(exp_vars, function(x) sum(x > 0))
  
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

events <- c("TOT", "DVT", "RX",  "OBV", "OBD",
            "OPT", "OPY", "ERT", "IPT", "HHT", "OMA")

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
  summarise_at(evt_sops, function(x) sum(x > 0))

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

