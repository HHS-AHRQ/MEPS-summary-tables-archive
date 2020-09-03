

# Helper functions ------------------------------------------------------------

# Add event and SOP labels
add_labels <- function(df, dictionary, key="ind",vars=c("rowLevels","colLevels"), replace=T){
  dictionary <- dictionary %>% mutate_if(is.factor, as.character)
  vars <- vars[vars %in% colnames(df)]
  for(var in vars){
    df$temp <- df[,var]
    df <- df %>%
      left_join(dictionary,by = c("temp" = key)) %>%
      mutate(temp = coalesce(values, temp))
    if(replace) newvar = var else newvar = paste0(var, "_label")
    df[,newvar] = df$temp
    df <- df %>% select(-temp, -values)
  }
  return(df)
}

add_all_labels <- function(df) {
  df %>%
    add_labels(sp_keys) %>%
    add_labels(spX_keys) %>%
    add_labels(sop_dictionary) %>%
    add_labels(evnt_use) %>% 
    add_labels(evnt_keys) %>%
    add_labels(event_dictionary) %>%
    add_labels(delay_dictionary)
}

adjust_levels <- function(df, new_levels) {
  nm = substitute(new_levels)
  new_levels <- new_levels %>% 
    setNames(paste0(nm, 0:(length(new_levels)-1))) %>% 
    stack %>% mutate_all(as.character)
  
  left_join(df, new_levels, by = c("levels" = "values")) %>%
    mutate(levNum = coalesce(ind, levNum)) %>%
    select(-ind)
}

adjust_text = function(D) {
  if(is.null(D)) return("")
  if(D %in% c(1, 10^-2)) return("")
  if(D == 10^3) return("in thousands")
  if(D == 10^6) return("in millions")
  if(D == 10^9) return("in billions")
}


get_totals <- function(grp,df,label="All persons"){
  totals <- df %>% filter(rowGrp=="ind",colGrp!=grp)
  totals %>%
    mutate(rowGrp=grp,rowLevels=label) %>%
    switch_labels
}

add_totals <- function(df, var = 'row') {
  
  df$var = df[,paste0(var,"Grp")]
  df$lev = df[,paste0(var,"Levels")]
  
  totals <- df %>% filter(var == "ind")
  all_grps <- df$var %>% unique %>% pop('ind')
  
  totals_list <- list()
  for(grp in all_grps %>% pop("sop")) {
    label = ifelse(grp == "event", "Any event", "All persons")
    totals_list[[grp]] <- totals %>% mutate(var = grp, lev = label)
  }  
  all_totals <- bind_rows(totals_list)
  all_totals[,paste0(var,"Grp")] = all_totals$var
  all_totals[,paste0(var,"Levels")] = all_totals$lev
  
  return(bind_rows(all_totals, df) %>% select(-var, -lev))
}

invertList <- function(list) {
  flatten <- list %>% unlist 
  if(is.null(names(flatten))) names(flatten) <- flatten
  invert <- names(flatten) %>% setNames(flatten)
  noGrps <- gsub("^.*\\.","", invert)
  return(noGrps)
}


# convert list to dataframe for merging labels
list_to_df <- function(list, key) {
  df <- list %>% stack 
  if(all(rownames(df) == as.character(1:nrow(df)))) {
    return(df %>% setNames(paste0(key,c("_var", "_label"))))
  } else {
    df <- cbind(df, rownames(df)) %>% 
      setNames(c("var", "group", "label")) %>%
      mutate_all(as.character) %>%
      mutate(
        label = ifelse(label == "", group, label),
        group = ifelse(label == group, "", group)) %>%
      mutate_all(as.factor)
    
    return(df %>% setNames(paste0(key,c("_var", "_group", "_label"))))
  }
}

# Formatting functions --------------------------------------------------------

format_tbl <- function(df, appKey) {
  
  fmt_tbl <- df %>%
    
    mutate(sample_size = ifelse(coef %in% c("meanEXP","medEXP"), n_exp, n)) %>% 
    
    mutate(RSE = se/coef,
           is.pct = (stat %>% startsWith("pct")),
           special_pct = (is.pct & (coef < 0.1) & (RSE < (0.1/coef-1)/1.96)),
           suppress = (sample_size < 60 | RSE > 0.5) | (se == 0),
           suppress = replace(suppress, special_pct, FALSE),
           star = (RSE > 0.3 & !suppress)) %>% 
    
    mutate(denom = replace(denom, is.na(denom), 1),
           digits = replace(digits, is.na(digits), 1),
           se_digits = replace(se_digits, is.na(se_digits), 1),
           coef = ifelse(suppress, NA, coef/denom),
           se   = ifelse(suppress, NA, se/denom))  %>%
    
    mutate(se   = formatNum(se,   d = se_digits),
           coef = formatNum(coef, d = digits),
           coef = ifelse(star, paste0(coef,"*"), coef)) %>% 
    
    select(-RSE, -is.pct, -special_pct, -suppress, -star, -denom, -digits, -se_digits)
  #select(Year, rowGrp, colGrp, rowLevels, colLevels, stat, coef, se, sample_size) 
  
  if(appKey == "hc_care") {
    fmt_tbl <- fmt_tbl  %>%
      mutate(
        colLevels = as.character(colLevels),
        colLevels = replace(colLevels, startsWith(colLevels,"afford"), "Couldn't afford"),
        colLevels = replace(colLevels, startsWith(colLevels,"insure"), "Insurance related"),
        colLevels = replace(colLevels, startsWith(colLevels,"other"), "Other"))
  }
  
  if(appKey == "hc_pmed") {
    
    fmt_tbl <- fmt_tbl %>% 
      mutate(rowLevels = str_to_title(rowLevels))
    
    # # Check abbreviations
    # abbrevs <- array()
    # for(lev in unique(fmt_tbl$rowLevels)) {
    #   components <- strsplit(lev, "/")[[1]] 
    #   abbrevs <- c(abbrevs, components[nchar(components) < 5])
    # }
    # print(unique(abbrevs))
    
    # Make abbreviations all caps
    abbrevs <- 
      c("ASA", "APAP", "PPA", "CPM", "PE", 
        "PB", "HC", "PSE", "DM", "TCN", "GG",  # "ADOL"
        "ALOH", "MGOH", "FA")
    
    for(abb in abbrevs) {
      ABB_str1 <- sprintf("^%s/", abb); re1 <- sprintf("%s/", abb);
      ABB_str2 <- sprintf("/%s/", abb); re2 <- ABB_str2;
      ABB_str3 <- sprintf("/%s$", abb); re3 <- sprintf("/%s", abb);
      
      fmt_tbl <- fmt_tbl %>%
        mutate(
          rowLevels = gsub(ABB_str1, re1, rowLevels, ignore.case = T),
          rowLevels = gsub(ABB_str2, re2, rowLevels, ignore.case = T),
          rowLevels = gsub(ABB_str3, re3, rowLevels, ignore.case = T))
    }
    
  }
  
  # Remove rows with too small n
  fmt_tbl <- fmt_tbl %>%
    group_by(rowLevels) %>%
    mutate(max_n = max(sample_size, na.rm=T)) %>%
    filter(max_n >= 60) %>%
    ungroup(rowLevels) %>%
    as.data.frame %>%
    select(-max_n, -sample_size)
  
  return(fmt_tbl)
}


format_hc_tables <- function(appKey, years, adj, all_possible = NA) {
  
  dir <- sprintf("data_tables/%s", appKey)
  if(missing(years)) years <- list.files(dir)
  
  fmt_dir <- sprintf("../formatted_tables/%s", appKey)
  dir.create(fmt_dir)
  
  adj$adjText <- sapply(adj$denom, adjust_text)
  
  stats <- statList[[appKey]] %>% unlist %>% setNames(NULL)
  rows <- rowGrps[[appKey]] %>% unlist %>% setNames(NULL)
  cols <- colGrps[[appKey]] %>% unlist %>% setNames(NULL)
  
  has_n <- any(grepl("n.csv", list.files(dir, recursive = T)))
  has_nexp <- any(grepl("n_exp.csv", list.files(dir, recursive = T)))
  
  # Loop through years
  
  for(year in years) { cat(year,"..")
    
    out_fmt <- sprintf("%s/DY%s.csv", fmt_dir, year)
    yrX <- paste0(substr(year, 3, 4), "X")
    
    # Load sample size data files
    n_df <- read.csv(sprintf("%s/%s/n.csv", dir, year), stringsAsFactors = F) %>%
      rm_v2 %>% dedup %>% add_all_labels

    if(has_nexp) {
      n_exp <- read.csv(sprintf("%s/%s/n_exp.csv", dir, year), stringsAsFactors = F) %>%
        rm_v2 %>% dedup %>% add_all_labels
    }
    
    # For 'use' app, need row x col and col x row
    if(appKey == 'hc_use'){
      n_df  <- bind_rows(n_df, switch_labels(n_df)) %>% dedup
      n_exp <- bind_rows(n_exp, switch_labels(n_exp)) %>% dedup
    }
    
    # Loop through stats and format
    tbs <- list()
    for(st in stats) {
      tb_stat <- 
        read.csv(sprintf("%s/%s/%s.csv", dir, year, st), stringsAsFactors = F) %>% 
        mutate(
          stat = st, 
          colLevels = gsub(yrX,"",colLevels),
          rowLevels = gsub(yrX,"",rowLevels)) 
      colnames(tb_stat)[colnames(tb_stat) %in% c(st, paste0(st,"_se"))] <- c('coef', 'se')
      
      tbs[[st]] <- tb_stat
    }
    
    full_tbls <- bind_rows(tbs) %>% rm_v2 %>% 
      dedup %>% add_all_labels 
    
    if(has_n) full_tbls <- full_tbls %>% left_join(n_df)
    if(has_nexp) full_tbls <- full_tbls %>% left_join(n_exp)
    
    # Remove 'OBO' and 'OPZ' -- no longer including non-phys events in output tables
    full_tbls <- full_tbls %>%
      filter(
        !colLevels %in% c('OBO', 'OPZ'),
        !rowLevels %in% c('OBO', 'OPZ'))
    
    fmt_tbl <- full_tbls %>%
      left_join(adj) %>%
      format_tbl(appKey = appKey) %>% 
      filter(!rowLevels %in% c("Missing", "Inapplicable")) %>%
      filter(!colLevels %in% c("Missing", "Inapplicable")) 
    

    # Do this before creating caption...to avoid mixing up row and col order
    if(appKey == "hc_use")
      fmt_tbl <- rbind(fmt_tbl, fmt_tbl %>% switch_labels) %>% dedup

    fmt_tbl <- fmt_tbl %>% 
      add_totals('row') %>% 
      add_totals('col') %>% 
      dedup  # If 'Any event' is already calculated, remove the version added in 'add_totals'
    
    
    # Remove impossible combinations (i.e. insurance 65+ for ages < 65)

      if(appKey == "hc_ins") {
        
        # print out to check that all removed obs are missing
        fmt_tbl %>%
          filter(
            (colGrp == "ins_lt65" & colLevels %>% startsWith("65+")) |
            (colGrp == "ins_ge65" & colLevels %>% startsWith("<65"))) %>%
          filter(!is.na(coef)) %>% 
          print
        
        
        fmt_tbl <- fmt_tbl %>%
          filter(
            !(colGrp == "ins_lt65" & colLevels %>% startsWith("65+")),
            !(colGrp == "ins_ge65" & colLevels %>% startsWith("<65"))
            )
      }
      
      if(appKey == "hc_care") {
        
        # print out to check that all removed obs are missing
          fmt_tbl %>% 
            filter(
              colGrp %>% startsWith("child_"),
              rowLevels %in% c("Married", "Widowed", "Separated", "Divorced"),
              !is.na(coef)) %>% 
            print
          
        
        fmt_tbl <- fmt_tbl %>%
          filter(
            !(colGrp %>% startsWith("child_") &
                rowLevels %in% c("Married", "Widowed", "Separated"))
          )
      }
    

    # Add stat/row/col labels and groups
    fmt_tbl <- fmt_tbl %>% 
      rename(row_var = rowGrp, col_var = colGrp, stat_var = stat) %>% 
      left_join(list_to_df(statList[[appKey]], "stat")) %>%
      left_join(list_to_df(rowGrps[[appKey]], "row")) %>%
      left_join(list_to_df(colGrps[[appKey]], "col")) 
 
    # For 'care', remove '(child)' from col_label (had to add in so 'stack' would work)
    
    fmt_tbl <- fmt_tbl %>%
      mutate(col_label = col_label %>% gsub(" (child)","",., fixed = T))
    
    rowLabels <- invertList(rowGrps[[appKey]])
    colLabels <- invertList(colGrps[[appKey]])
    
    # Add caption as variable in table
    fmt_tbl$byGrps <- fmt_tbl$statExtra <- ""
    for(row in unique(fmt_tbl$row_var)) {
      for(col in unique(fmt_tbl$col_var)) {
        this_tbl = fmt_tbl$row_var == row & fmt_tbl$col_var == col
        
        rowN <- ifelse(row == 'ind', '', rowLabels[row]) %>% tolower
        colN <- ifelse(col == 'ind', '', colLabels[col]) %>% tolower
        byG <- c(rowN, colN) %>% pop('') %>% paste0(collapse = " and ")
        byGrps <- ifelse(byG == "", "", paste(" by",byG))
        fmt_tbl$byGrps[this_tbl] <- byGrps
        
        if(appKey == "hc_care") {
          #care_caption <- sprintf("%s, %s", careCaption[col], tolower(fmt_tbl$stat_label[this_tbl]))
          #fmt_tbl$stat_label[this_tbl] <- care_caption
          fmt_tbl$byGrps[this_tbl] <- ifelse(rowN == "", "", paste(" by",rowN))
        }
      }
    }
    
    if(appKey == "hc_use") {
      fmt_tbl <- fmt_tbl %>%
        mutate(
          statExtra = replace(
            statExtra, stat_var == 'totPOP' & (row_var == 'event' | col_var == 'event'), 
            'with an event'),
          
          statExtra = replace(
            statExtra, stat_var == 'totPOP' & (row_var == 'sop' | col_var == 'sop'), 
            'with an expense')
        ) 
    }
    
    if(appKey == "hc_care") {
      fmt_tbl <- left_join(fmt_tbl, careCaption) %>%
        mutate(caption = sprintf("%s, %s", caption, tolower(stat_label))) 
    } else {
      fmt_tbl <- fmt_tbl %>%
        mutate(caption = stat_label) 
    }
    
    fmt_tbl <- fmt_tbl %>%
      mutate(caption = 
               sprintf("%s %s %s (standard errors) %s, United States", 
                       caption, adjText, statExtra, byGrps) %>% 
               gsub("($)","",., fixed = T) %>%
               gsub("(%)","",., fixed = T) %>%
               gsub("[[:space:]]+", " ",.) %>%
               gsub(" ,",",",.)) %>%
      
      select(-one_of("n", "n_se", "n_exp", "n_exp_se", "adjText", "byGrps", "statExtra")) %>%
      
      select(one_of("stat_group", "stat_var", "stat_label",
                    "row_group", "row_var", "row_label", "rowLevels",
                    "col_group", "col_var", "col_label", "colLevels",
                    "coef", "se", "caption")) %>%
      
      filter(!(row_var == col_var & row_var != 'ind')) %>%
      
      mutate(
        stat_var = factor(stat_var, levels = stats),
        row_var  = factor(row_var, levels = rows),
        col_var  = factor(col_var, levels = cols)) %>%
      
      arrange(stat_var, row_var, col_var)
    
    # Fill in with 'DNC' (data not collected) for hc_care app, for even/odd years
    if(appKey == "hc_care" & year >= 2018) {
      
      fill_categories <- full_join(
        fmt_tbl %>% mutate(current_year = TRUE),
        all_possible %>% mutate(universe = TRUE))

      missing_categories <- fill_categories %>% 
        filter(is.na(current_year), universe) %>%
        count(col_var) %>% pull(col_var)

      if(year %% 2 == 0) {
        
        miss_even <- missing_categories %>% grep("adult|child|rsn|difficulty", ., value = T)
        
        fmt_tbl <- fill_categories %>%
          mutate(
            skipped = (is.na(current_year) & universe & col_var %in% miss_even),
            coef = ifelse(skipped, "DNC", coef),
            se   = ifelse(skipped, "DNC", se)) %>%
          select(-current_year, -universe, -skipped)
      }
    }
    
    write.csv(fmt_tbl, file = out_fmt, row.names = F) 
  } # end for year in years
  
}

