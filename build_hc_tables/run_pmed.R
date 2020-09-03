# Create directory and define subgroups, stats --------------------------------

appKey <- 'hc_pmed'

tbl_dir <- sprintf("data_tables/%s", appKey)
dir.create(tbl_dir)

row_grps <- rowGrps_R[[appKey]]
col_grps <- colGrps_R[[appKey]]


# Run for specified year(s) ---------------------------------------------------

for(year in year_list) {
  dir.create(sprintf('%s/%s', tbl_dir, year))

  yr <- substring(year, 3, 4)

# Load files and define svydesigns --------------------------------------------
  source("code/load_pmed.R", echo = T) # Load RX event files
  source("code/dsgn_pmed.R", echo = T) # Define all survey design objects

# Run for prescribed medicines ------------------------------------------------
  RXsub <- subset(RXdsgn, !RXNDC %in% c("-9","-15") & !RXDRGNAM %in% c("-9","-15"))

  res <- list()
  res[["totPOP"]] <- svyby(~count, by = ~RXDRGNAM, FUN = svytotal, design = DRGdsgn)
  res[["totEXP"]] <- svyby(~RXXPX, by = ~RXDRGNAM, FUN = svytotal, design = RXsub)
  res[["totEVT"]] <- svyby(~count, by = ~RXDRGNAM, FUN = svytotal, design = RXsub)
  res[["n"]]      <- svyby(~count, by = ~RXDRGNAM, FUN = unwtd.count, design = DRGdsgn)

  # Format and output to csv
  for(stat in names(res)) {
    res[[stat]] %>%
      setNames(c("rowLevels", stat, p(stat, "_se"))) %>%
      mutate(rowGrp = "RXDRGNAM", colGrp = "ind", colLevels = "Total") %>%
      update.csv(file = sprintf("%s/%s.csv", year, stat), dir = tbl_dir)
  }

# Run for therapeutic classes -------------------------------------------------
  res <- list()
  res[["totPOP"]] <- svyby(~count, by = ~TC1name, FUN = svytotal, design = TC1dsgn)
  res[["totEXP"]] <- svyby(~RXXPX, by = ~TC1name, FUN = svytotal, design = RXdsgn)
  res[["totEVT"]] <- svyby(~count, by = ~TC1name, FUN = svytotal, design = RXdsgn)
  res[["n"]]      <- svyby(~count, by = ~TC1name, FUN = unwtd.count, design = TC1dsgn)

  # Format and output to csv
  for(stat in names(res)) {
    res[[stat]] %>%
      setNames(c("rowLevels", stat, p(stat, "_se"))) %>%
      mutate(rowGrp = "TC1name", colGrp = "ind", colLevels = "Total") %>%
      update.csv(file = sprintf("%s/%s.csv", year, stat), dir = tbl_dir)
  }

} # END for year in year_list
