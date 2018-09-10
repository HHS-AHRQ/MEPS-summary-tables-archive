

# Convert to JSON -------------------------------------------------------------

data_toJSON <- function(appKey, pivot = F) {
  
  dir <- sprintf("../mepstrends/%s", appKey)
  tbl_dir <- sprintf("../formatted_tables/%s", appKey)
  
  # delete data folder and create new one
  unlink(sprintf('%s/json/data', dir), recursive = T)
  dir.create(sprintf('%s/json/data', dir), recursive = T)
  
  load(sprintf("../formatted_tables/%s/%s.Rdata", appKey, appKey))
  
  all_stats <- MASTER_TABLE

  # # Check for groups that are missing all years (may be 'impossible' groups)
  #   miss_groups <- all_stats %>%
  #     group_by(row_var, col_var, rowLevels, colLevels) %>%
  #     mutate(n_miss = mean(is.na(coef))) %>%
  #     filter(n_miss >= 1) %>%
  #     select(row_var, col_var, rowLevels, colLevels, coef, stat_var,n_miss)  %>%
  #     ungroup %>% unique %>%
  #     arrange(row_var, col_var, rowLevels) 
  #   
  #   write.csv(miss_groups, file = paste0("miss_",appKey,".csv"))
    
 
  # check for zeros after rounding
  #zeros <- all_stats %>% filter(coef %in% c("0", "0.0", "0.00") | se %in% c("0", "0.0", "0.00"))
  #write.csv(zeros, file = paste0("zeros_",appKey,".csv"))
  
  # Factor levels ----------------------------
  rowFactors <- all_stats %>% select(row_var, rowLevels) %>% setNames(c("grp", "levels"))
  colFactors <- all_stats %>% select(col_var, colLevels) %>% setNames(c("grp", "levels"))
  
  if(pivot) rowFactors = NULL
  
  factors <- bind_rows(rowFactors, colFactors) %>%
    unique %>%
    arrange(grp) %>%
    group_by(grp) %>%
    reorder_levels(age_levels) %>%
    reorder_levels(freq_levels) %>%
    reorder_levels(racesex_levels) %>%
    mutate(levNum = paste0(grp, LETTERS[row_number()])) %>%
    ungroup
  # -----------------------------------------
  
  max_ncol <- 0
  for(st in unique(all_stats$stat_var)){ cat("\n",st,":")
    for(col in unique(all_stats$col_var)) { cat(col,", ")
      
      filter_tbl <- all_stats %>% filter(stat_var == st, col_var == col)

      if(nrow(filter_tbl) == 0) {
        cat("\nERROR! for", st, "and", col,"\n")
        next # don't do this: need a warning if some combos aren't available
      }
      
      sub_tbl <- filter_tbl %>% tbl_df %>% 
        gather(class, value, coef, se) %>% 
        left_join(factors, by = c("col_var" = "grp", "colLevels" = "levels")) %>%
        arrange(levNum) %>% 
        unite(key1, colLevels, levNum, sep = "__") %>%
        mutate(key1 = factor(key1, levels = unique(key1))) %>%
        arrange(key1, Year, row_var, rowLevels, stat_var, class) %>%
        select(-col_var) 
      
      if(pivot){
        pre_wide <- sub_tbl %>% unite(key, key1, Year, stat_var, class, sep = "__") %>% mutate(Year = "All")
      } else {
        pre_wide <- sub_tbl %>% unite(key, key1, stat_var, class, sep = "__")
      }
      
      app_wide <- pre_wide %>% 
        left_join(factors, by = c("row_var" = "grp", "rowLevels" = "levels")) %>%
        rename(rowLevNum = levNum) %>%
        mutate(rowLevels = ifelse(row_var == 'ind', Year, rowLevels)) %>%
        mutate(key = factor(key, levels = unique(key))) %>%
        spread(key, value) 
      
      app_wide <- app_wide  %>% 
        mutate(selected = 0) %>%
        select(Year, row_var, rowLevels, rowLevNum, selected, one_of(colnames(app_wide))) %>%
        arrange(rowLevNum)
      
      if(!pivot){
        app_wide <- app_wide %>% arrange(-Year)
        max_ncol <- max(max_ncol, ncol(app_wide))
      } else {
        ncol_trend <- sum(grepl("ind", colnames(app_wide))) + 4
        max_ncol <- max(max_ncol, ncol_trend)
      }
      
      # remove columns not needed for json data
      app_wide <- app_wide %>%
        select(-one_of("stat_label", "row_group", "row_label", "col_label"))
      
      # Add 'subLevels' if not in data
      if(!'subLevels' %in% colnames(app_wide)) {
        app_wide$subLevels = ""
      }
      
      classes <- colnames(app_wide)
      classes <- classes[classes != 'caption']
      cnames <- array()
      for(i in 1:length(classes)){
        sp = str_split(classes[i],"__")[[1]]
        cnames[i] = sp[1]
        if(sp[1] == "Total") cnames[i] = sp[3]
      }
      jsonClasses <- toJSON(classes, dataframe = "values", na = "null")
      jsonNames   <- toJSON(cnames,  dataframe = "values", na = "null")
      
      for(row in unique(app_wide$row_var)){ #print(row)
        if(row == col & row != 'ind') next
        row_wide <- app_wide %>% filter(row_var == row)

        for(sG in unique(row_wide$subLevels)) {
          sG_wide <- row_wide %>% filter(subLevels == sG)

          caption <- sG_wide$caption %>% unique
          
          sG_wide <- sG_wide %>% select(-caption)
          
          jsonCaption <- toJSON(caption)
          
          jsonData <- toJSON(sG_wide, dataframe = "values", na = "null")
          json_OUT <- sprintf( 
            '{"data": %s, "classes": %s, "names": %s, "caption": %s}', 
            jsonData,    jsonClasses,  jsonNames,   jsonCaption)
          
          filename <- sprintf("%s/json/data/%s__%s__%s__%s.json", dir, st, row, col, rm_spec(sG))
          write(json_OUT, file = filename)
          
        } # subGrp loop
      } # row loop
      
    } # col loop
  } # stat loop
  
  # Initialize column classes
  coefCols <- rep('
                  {title: "", className: "coef", searchable: false, render: coefDisplay}', max_ncol)
  seCols <- rep('
                {title: "", className: "se", searchable: false, render: seDisplay}', max_ncol)
  statCols <- c(rbind(coefCols,seCols)) %>% paste0(collapse=",\n")
  
  initCols <- sprintf('[
                      { title: "Year", className: "sub", "visible": false},
                      { title: "row_var", className: "sub", "visible": false},
                      { title: "rowLevels" , className: "main"},
                      { title: "rowLevNum" , className: "sub", "visible": false},
                      { title: "selected",   className: "sub", "visible" : false},
                      %s]', statCols)
  
  # Initial level selection for groups
  factors = factors %>% 
    filter(grp != 'ind') %>% # ind screws up pivot tables
    filter(!levels %in% exclude_initial)
  
  initLevels = list()
  for(gp in unique(factors$grp)) {
    sub = factors %>% filter(grp == gp)
    initLevels[[gp]] = as.list(sub$levels) %>% setNames(sub$levNum)
  }
  
  init_levels <- toJSON(initLevels, auto_unbox = T)
  sub_levels <- toJSON(subLevels, auto_unbox = T)
  isPivot <- ifelse(pivot, 'true', 'false')
  
  json_INIT <- sprintf(
    "var isPivot = %s; var initCols = %s; var initLevels = %s; var subLevels = %s;", 
    isPivot, initCols, init_levels, sub_levels)  
  
  write(json_INIT, file = sprintf("%s/json/init.js", dir))
}


notes_toJSON <- function(appKey, notes = "") {
  dir <- sprintf("../mepstrends/%s", appKey)
  
  years <- get_puf_names()$Year
  
  # For code tab
  pufNames <- lapply(years, get_puf_names, web = F) %>% setNames(years)
  
  # For years after 2013, set 'Multum' to the 2013 dataset
  for(year in 2014:max(years)) {
    pufNames[[as.character(year)]]$Multum = pufNames[['2013']]$Multum
  }

  appKeyJ    <- sprintf("var appKey = '%s';", appKey)
  pufNamesJ  <- sprintf("var pufNames = %s;", toJSON(pufNames, auto_unbox = T))
  mepsNotesJ <- sprintf("var mepsNotes = %s;", toJSON(notes, auto_unbox = T))
  
  notes_JSON <- paste(c(appKeyJ, pufNamesJ, mepsNotesJ), collapse = "\n\n")
  
  write(notes_JSON, file = sprintf("%s/json/notes.js", dir))
}
