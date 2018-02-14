# Run functions -----------------------------------------------------------------

# USE AND EXP, PMED, COND
standardize <- function(df, stat, rowGrp, colGrp, gather = T){
  out <- df %>% select(-contains("FALSE")) 
  key <- c(stat, paste0(stat, "_se"))
  
  if(ncol(out) > 4 & gather) {
    out <- out %>% gather_wide(rowGrp, colGrp, altsub = "insurance_v2X")
  }
  
  names(out)[!names(out) %in% c("ind", "sop", "event", rowGrp, colGrp)] <- key
  out <- out %>% 
    mutate(ind = "Total") %>% 
    mutate(rowGrp = rowGrp, colGrp = colGrp) 
  
  if(rowGrp %in% names(out)) out <- out %>% mutate_(rowLevels = rowGrp)
  if(colGrp %in% names(out)) out <- out %>% mutate_(colLevels = colGrp)
  
  out %>% select(rowGrp, colGrp, one_of(c("rowLevels", "colLevels", key)))
}

gather_wide <- function(df, row, col, altsub = ""){
  grps <- c(row, col)
  spr_grp <- grps[!grps %in% names(df)]
  if(length(spr_grp) == 0) spr_grp = ""
  df <- df %>% 
    select(-contains("FALSE")) %>%
    gather_("group", "coef", setdiff(names(.), c(grps,"ind"))) %>%
    mutate(group = gsub(" > 0TRUE","",group)) %>%
    mutate(group = gsub(spr_grp,"",group)) %>%
    mutate(group = gsub(altsub,"",group)) %>%
    separate(group, c("stat", "grp"), sep="\\.",fill="left") %>%
    mutate(stat = replace(stat,is.na(stat),"stat")) %>%
    mutate(grp = factor(grp, levels = unique(grp))) %>%
    spread(stat, coef)
  
  repl = grps[!grps %in% names(df)]
  df[,repl] = df$grp
  df %>% select_(row, col, "stat", "se")
}


update.csv <- function(add,file,dir){
  init = !(file %in% list.files(dir,recursive=T))
  fileName <- sprintf("%s/%s",dir,file) %>% gsub("//","/",.)
  write.table(add,file=fileName,append=(!init),sep=",",col.names=init,row.names=F)
}


done <- function(outfile,...,dir="/"){
  if(!outfile %in% list.files(dir,recursive=T)) return(FALSE)
  
  df <- read.csv(paste0(dir,"/",outfile))
  chk <- list(...)
  for(i in 1:length(chk)){
    name=names(chk)[i]
    value=chk[[i]]
    df <- df %>% filter_(sprintf("%s=='%s'",name,value))
  }
  is.done = (nrow(df)>0)
  if(is.done) print('skipping')
  return(is.done)
}

pop <- function(vec, ...) vec[!vec %in% unlist(list(...))]

add_v2X <- function(names) names %>% append(c('agegrps_v2X', 'insurance_v2X'))
add_v3X <- function(names) names %>% append(c('agegrps_v2X', 'agegrps_v3X'))

findKey <- function(nm, keys) {
  keys = as.character(keys)
  str = keys[sapply(keys, function(x) grepl(x, nm)) %>% which]  
  if(length(str) == 0) return(NA)
  return(str)
}

# Merge functions -----------------------------------------------------------------

# Add event and SOP labels
add_labels <- function(df, dictionary, key="ind",vars=c("rowLevels","colLevels")){
  dictionary <- dictionary %>% mutate_if(is.factor, as.character)
  vars <- vars[vars %in% colnames(df)]
  for(var in vars){
    df <- df %>%
      mutate_(temp = var) %>%
      left_join(dictionary,by = c("temp" = key)) %>%
      mutate(temp = coalesce(values, temp))
    df[,var] = df$temp
    df <- df %>% select(-temp, -values)
  }
  return(df)
}

rm_v2 <- function(df){
df%>% mutate(rowGrp = rowGrp %>% gsub("_v2X","",.) %>% gsub("_v3X","",.),
             colGrp = colGrp %>% gsub("_v2X","",.) %>% gsub("_v3X","",.))
}

rm_na <- function(vec) {
  vec[!is.na(vec)]
}

readSource <- function(file,...,dir=".") {
  fileName <- sprintf("%s/%s",dir,file) %>% gsub("//","/",.)
  codeString <- readChar(fileName,file.info(fileName)$size)
  codeString <- codeString %>% gsub("\r","",.) # %>% gsub("\n","<br>",.)
  # codeString <- codeString %>% rsub(...) %>% gsub("\r","",.)
  codeString
}

run <- function(codeString,verbose=T){
  if(verbose) writeLines(codeString)
  eval(parse(text=codeString),envir=.GlobalEnv)
}

switch_labels <- function(df){
  df %>%
    mutate(g1=rowGrp,g2=colGrp,l1=rowLevels,l2=colLevels) %>%
    mutate(rowGrp=g2,colGrp=g1,rowLevels=l2,colLevels=l1) %>%
    select(-g1,-g2,-l1,-l2)
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


reverse <- function(df) df[nrow(df):1,]

dedup <- function(df){
  df %>%
    reverse %>%
    distinct(Year,stat,rowGrp,colGrp,rowLevels,colLevels,.keep_all=TRUE) %>%
    reverse
}

rsub <- function(string,...,type='r') {
  repl = switch(type,
                'r'='\\.%s\\.',
                'sas'='&%s\\.')
  
  sub_list = list(...) %>% unlist
  for(l in names(sub_list)){
    original <- sprintf(repl,l)
    replacement <- sub_list[l]
    string <- gsub(original,replacement,string)
  }
  return(string)
}

adjust_text = function(D) {
  if(is.null(D)) return("")
  if(D %in% c(1, 10^-2)) return("")
  if(D == 10^3) return("in thousands")
  if(D == 10^6) return("in millions")
  if(D == 10^9) return("in billions")
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

reorder_levels <- function(df,new_levels){
  orig_l1 = unique(df$levels)
  new_l1 = c(orig_l1[!orig_l1 %in% new_levels],new_levels)

  df %>%
    mutate(levels = factor(levels,levels=new_l1)) %>%
    arrange(levels) %>%
    mutate(levels = as.character(levels))
}

formatNum <- function(x, d) {
  xnum = x[!is.na(x)]
  dnum = d[!is.na(x)]

  spf <- paste0("%.",dnum,"f")
  fm_digits <- sprintf(spf, xnum)
  new_x <- prettyNum(fm_digits, big.mark = ",", preserve.width = "none")

  x[!is.na(x)] <- new_x
  return(x)
}

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

    select(Year, rowGrp, colGrp, rowLevels, colLevels, stat, coef, se, sample_size) 
  
  if(appKey == "care") {
    fmt_tbl <- fmt_tbl  %>%
      mutate(
        colLevels = as.character(colLevels),
        colLevels = replace(colLevels, startsWith(colLevels,"afford"), "Couldn't afford"),
        colLevels = replace(colLevels, startsWith(colLevels,"insure"), "Insurance related"),
        colLevels = replace(colLevels, startsWith(colLevels,"other"), "Other"))
  }
  
  if(appKey == "pmed") {
    
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

# Convert to JSON -------------------------------------------------------------

add_all_labels <- function(df) {
  df %>%
    add_labels(sp_keys) %>%
    add_labels(sop_dictionary) %>%
    add_labels(evnt_use) %>% 
    add_labels(evnt_keys) %>%
    add_labels(event_dictionary) %>%
    add_labels(delay_dictionary)
}

load_years <- function(appKey, stats, years, adj) {

  dir <- sprintf("../tables/%s", appKey)
  if(missing(years)) years <- list.files(dir)
  
  has_nexp <- any(grepl("n_exp.csv", list.files(dir,recursive = T)))

  tbs <- n_df <- n_exp <- list()
  for(year in years) { cat(year,"..")
    yrX <- paste0(substr(year, 3, 4), "X")
    for(stat in stats) {
      tb_stat <- 
        read.csv(sprintf("%s/%s/%s.csv", dir, year, stat), stringsAsFactors = F) %>% 
        mutate(stat = stat, Year = year) %>%
        mutate(
          colLevels = gsub(yrX,"",colLevels),
          rowLevels = gsub(yrX,"",rowLevels)) 
      colnames(tb_stat)[colnames(tb_stat) %in% c(stat, paste0(stat,"_se"))] <- c('coef', 'se')

      tbs[[paste0(stat,year)]] <- tb_stat
    }
  }

  n_df <- lapply(years, function(x)
    read.csv(sprintf("%s/%s/n.csv", dir, x), stringsAsFactors = F) %>% mutate(Year = x)) %>%
    bind_rows %>% rm_v2 %>% dedup %>% add_all_labels

  if(has_nexp){
    n_exp <- lapply(years, function(x)
      read.csv(sprintf("%s/%s/n_exp.csv", dir, x), stringsAsFactors = F) %>% mutate(Year = x)) %>%
      bind_rows %>% rm_v2 %>% dedup %>% add_all_labels
  }

  if(appKey == 'use'){
    n_df  <- bind_rows(n_df, switch_labels(n_df)) %>% dedup
    n_exp <- bind_rows(n_exp, switch_labels(n_exp)) %>% dedup
  }
    
  full_tbls <- bind_rows(tbs) %>% rm_v2 %>% dedup %>% add_all_labels %>% left_join(n_df)
  
  if(has_nexp) full_tbls <- full_tbls %>% left_join(n_exp)

  full_tbls <- full_tbls %>%
    left_join(adj) %>%
    format_tbl(appKey = appKey) %>%
    filter(!rowLevels %in% c("Missing", "Inapplicable")) %>%
    filter(!colLevels %in% c("Missing", "Inapplicable")) %>%
    add_totals('row') %>%
    add_totals('col')
  
  full_tbls <- full_tbls %>% 
    group_by(rowGrp, colGrp, rowLevels, colLevels) %>%
    mutate(n_miss = mean(is.na(coef))) %>%
    filter(n_miss < 1) %>%
    ungroup %>%
    select(-n_miss)
    
  return(full_tbls)
}



data_toJSON <- function(appKey, years, adj, pivot = F) {

  dir <- sprintf("../mepstrends/hc_%s", appKey)
  
  # delete data folder and create new one
    unlink(sprintf('%s/json/data', dir), recursive = T)
    dir.create(sprintf('%s/json/data', dir))
  
  stats <- statList[[appKey]] %>% unlist(use.names = F)

  all_stats <- load_years(appKey = appKey, stats = stats, years = years, adj = adj)
  
  # check for zeros after rounding
    zeros <- all_stats %>% filter(coef %in% c("0", "0.0", "0.00") | se %in% c("0", "0.0", "0.00"))
    write.csv(zeros, file = paste0("zeros_",appKey,".csv"))
  
  # Factor levels ----------------------------
    rowFactors <- all_stats %>% select(rowGrp, rowLevels) %>% setNames(c("grp", "levels"))
    colFactors <- all_stats %>% select(colGrp, colLevels) %>% setNames(c("grp", "levels"))
    
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
  if(appKey == "use")
    all_stats <- rbind(all_stats, all_stats %>% switch_labels) %>% dedup
    
  for(st in stats){ cat("\n",st,":")
    for(col in unique(all_stats$colGrp)) { cat(col,", ")
      
        sub_tbl <- all_stats %>% 
          filter(stat == st, colGrp == col) %>% tbl_df %>% 
          gather(class, value, -rowGrp, -colGrp, -rowLevels, -colLevels, -Year, -stat) %>% 
          left_join(factors, by = c("colGrp" = "grp", "colLevels" = "levels")) %>%
          arrange(levNum) %>% 
          unite(key1, colLevels, levNum, sep = "__") %>%
          mutate(key1 = factor(key1, levels = unique(key1))) %>%
          arrange(key1, Year, rowGrp, rowLevels, stat, class) %>%
          select(-colGrp) 
        
        if(pivot){
          pre_wide <- sub_tbl %>% unite(key, key1, Year, stat, class, sep = "__") %>% mutate(Year = "All")
        } else {
          pre_wide <- sub_tbl %>% unite(key, key1, stat, class, sep = "__")
        }
        
        app_wide <- pre_wide %>% 
          left_join(factors, by = c("rowGrp" = "grp", "rowLevels" = "levels")) %>%
          rename(rowLevNum = levNum) %>%
          mutate(rowLevels = ifelse(rowGrp == 'ind', Year, rowLevels)) %>%
          mutate(key = factor(key, levels = unique(key))) %>%
          spread(key, value) 
        
        app_wide <- app_wide  %>% 
          mutate(selected = 0) %>%
          select(Year, rowGrp, rowLevels, rowLevNum, selected, one_of(colnames(app_wide))) %>%
          arrange(rowLevNum)
        
        if(!pivot){
          app_wide <- app_wide %>% arrange(-Year)
          max_ncol <- max(max_ncol, ncol(app_wide))
        } else {
          ncol_trend <- sum(grepl("ind", colnames(app_wide))) + 4
          max_ncol <- max(max_ncol, ncol_trend)
        }
        
        classes <- colnames(app_wide)
        cnames <- array()
        for(i in 1:length(classes)){
          sp = str_split(classes[i],"__")[[1]]
          cnames[i] = sp[1]
          if(sp[1] == "Total") cnames[i] = sp[3]
        }
        jsonClasses <- toJSON(classes, dataframe = "values", na = "null")
        jsonNames   <- toJSON(cnames,  dataframe = "values", na = "null")
        
        for(row in unique(app_wide$rowGrp)){ #print(row)
          if(row == col & row != 'ind') next
          
          row_wide <- app_wide %>% filter(rowGrp == row)
          jsonData <- toJSON(row_wide, dataframe = "values", na = "null")
          json_OUT <- sprintf( '{"data": %s, "classes": %s, "names": %s}', jsonData, jsonClasses, jsonNames)
          filename <- sprintf("%s/json/data/%s__%s__%s.json", dir, st, row, col)
          write(json_OUT, file = filename)
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
      { title: "Year",   className: "sub", "visible": false},
      { title: "rowGrp", className: "sub", "visible": false},
      { title: "rowLevels" , className: "main"},
      { title: "rowLevNum" , className: "sub", "visible": false},
      { title: "selected",   className: "sub", "visible" : false},
    %s]', statCols)
  
  adj$text = sapply(adj$denom, adjust_text)
  adjustment <- sprintf("%s: '%s'", adj$stat, adj$text) %>% paste(collapse = ", ")
    
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
    "var isPivot = %s; var initCols = %s; var initLevels = %s; var subLevels = %s; var adjustStat = {%s};", 
     isPivot, initCols, init_levels, sub_levels, adjustment)  
  
  write(json_INIT, file = sprintf("%s/json/init.js", dir))
}

code_toJSON <- function(appKey, years) {
  dir <- sprintf("../mepstrends/hc_%s", appKey)
  
  # Code snippets
  subgrps  <- demo_grps %>% unlist(use.names = F)
  pufNames <- lapply(years, get_puf_names, web = F) %>% setNames(years)
  
  # For years after 2013, set 'Multum' to the 2013 dataset
    for(year in 2014:max(years)) {
      pufNames[[as.character(year)]]$Multum = pufNames[['2013']]$Multum
    }
  
  if(appKey != 'use') grpCode <- grpCode[!names(grpCode) %in% c("event", "sop", "event_sop")]
  
  appKeyJ <- sprintf("var appKey = '%s';", appKey)
  careCaptionJ <- sprintf("var careCaption = %s;", toJSON(careCaption, auto_unbox = T))
  
  loadPkgsJ <- sprintf("var loadPkgs = %s;", toJSON(loadPkgs, auto_unbox = T))
  loadFYCJ  <- sprintf("var loadFYC  = %s;", toJSON(loadFYC[[appKey]],  auto_unbox = T))
  loadCodeJ <- sprintf("var loadCode = %s;", toJSON(loadCode[[appKey]], auto_unbox = T))
  grpCodeJ  <- sprintf("var grpCode  = %s;", toJSON(grpCode, auto_unbox = T))
  dsgnCodeJ <- sprintf("var dsgnCode = %s;", toJSON(dsgnCode[[appKey]], auto_unbox = T))
  statCodeJ <- sprintf("var statCode = %s;", toJSON(statCode[[appKey]], auto_unbox = T))
  
  subgrpsJ  <- sprintf("var subgrps  = %s;", toJSON(subgrps, auto_unbox = T))
  byVarsJ   <- sprintf("var byVars   = %s;", toJSON(byVars[[appKey]], auto_unbox = T))
  pufNamesJ <- sprintf("var pufNames = %s;", toJSON(pufNames, auto_unbox = T))
  
  # Notes
  mepsNotesJ <- sprintf("var mepsNotes = %s;", toJSON(notes, auto_unbox = T))
  
  code_JSON <- paste(
    c(appKeyJ, careCaptionJ, loadPkgsJ, loadFYCJ, loadCodeJ, grpCodeJ, dsgnCodeJ, statCodeJ, 
      subgrpsJ, byVarsJ, pufNamesJ, mepsNotesJ), collapse = "\n\n")
  
  write(code_JSON, file = sprintf("%s/json/code.js", dir))
}


# 508 form functions and html builder ------------------------------------------------------------------------

tab_li <- function(id, label, class = "") {
  tags$li(class = class,
    tags$a('data-toggle' = 'tab', href = sprintf('#%s-tab',id), id = sprintf('%s-pill',id),
           tags$span(class = sprintf("tab-title %s-tab",id), label)))
}

caption <- function(id) {
  tags$span(id = sprintf('%s-caption',id), role = 'region', 'aria-live' = 'polite', class = 'caption')
}

actionButton508 <- function (inputId, label, usaStyle = NULL, class="", icon = NULL, width = NULL, ...){
  value <- restoreInput(id = inputId, default = NULL)
  tags$button(
    id = inputId, 
    type = "button",
    class = sprintf("action-button %s",class),
    class = paste(c("usa-button", usaStyle),collapse="-"), 
    `data-val` = value,
    list(icon, label), ...)
}


selectInput508 <- function (inputId, choices = "", selected = NULL, label=NULL, width = NULL, size = NULL){
  choices <- choicesWithNames(choices)
  if(is.null(selected)) {
    selected <- firstChoice(choices)
  }else{
    selected <- as.character(selected)
  }
  
  selectTag <- tags$select(id = inputId, size = size, selectOptions(choices, selected))
  labelTag <- if(!is.null(label)) tags$label(label, 'for'=inputId)
  
  tagList(labelTag, selectTag)
}

checkboxInput508 <- function(inputId, label, value = FALSE, inline=FALSE, class=""){
  inputTag <- tags$input(id = inputId, type = "checkbox", name=inputId, value=inputId,class=class)
  if (!is.null(value) && value) inputTag$attribs$checked <- "checked"
  labelTag <- tags$label('for'=inputId,label)
  if(inline){
    inputTag$attribs$style = 'display: inline;'
    labelTag$attribs$style = 'display: inline;'
  }
  tagList(inputTag,labelTag)
}

checkboxGroupInput508 <- function (inputId, choices = "", label=NULL, selected = NULL, inline=FALSE) {
  choices <- choicesWithNames(choices)
  
  if(!is.null(selected)) selected <- as.character(selected)
  
  if (is.null(choices) && is.null(choiceNames) && is.null(choiceValues)) {
    choices <- character(0)
  }
  
  options <- generateOptions508(inputId, choices, selected, inline)
  
  labelTag <- ""
  if(!is.null(label)) labelTag <- tags$label(label)
  legendTag <- tags$legend(label,class="usa-sr-only")
  
  
  tags$fieldset(id=inputId,
                class="usa-fieldset-inputs usa-sans shiny-input-checkboxgroup", ## !important shiny class
                labelTag,
                legendTag,
                tags$ul(class="usa-unstyled-list",options)
  )
}

radioButtons508 <- function(inputId, label, choices, selected = NULL, inline = FALSE, width = NULL,class="") {
  choices <- choicesWithNames(choices)
  selected <- if(is.null(selected)){
    choices[[1]]
  }else {
    as.character(selected)
  }
  if(length(selected) > 1) stop("The 'selected' argument must be of length 1")
  
  options <- generateOptions508(inputId, choices, selected, inline, type = "radio")
  legendTag <- tags$legend(label,class="em-legend")
  
  tags$fieldset(
    id=inputId,
    class= paste("usa-fieldset-inputs usa-sans shiny-input-radiogroup",class), ## !important shiny class
    legendTag,
    tags$ul(class="usa-unstyled-list",options)
  )
}

generateOptions508 <- function (inputId, choices, selected, inline=FALSE, type = "checkbox"){
  options <- mapply(
    choices, names(choices),
    FUN = function(value,name) {
      unique_id = paste(inputId,value,sep="-") ## need this in case using same choices across namespaces
      inputTag <- tags$input(id = unique_id, type = type, name = inputId, value = value)
      if(value %in% selected) inputTag$attribs$checked <- "checked"
      labelTag <- tags$label('for'=unique_id, name)
      listTag <- tags$li(inputTag,labelTag)
      
      if(inline) listTag$attribs$style="display: inline-block; padding-right: 30px;"
      listTag
    }, SIMPLIFY = FALSE, USE.NAMES = FALSE)
  
  div(class="shiny-options-group",options) ## need shiny-options-group class to replace, not append, new choices
}

downloadButton508 <- function (id, label = "Download"){
  tags$a(id = id, title = "", 'data-original-title' = label, 
         tabindex = 0,
         class = 'em-tooltip usa-button download-button',
         tags$span(class = 'usa-sr-only', label))
}

searchBox508 <- function(id, label = "Search") {
  div(class = 'inline',
      div(
        tags$label('for' = 'search', label),
        tags$input(id = id, value = "", class = "form-control", type = 'text')  
      ))
}

dropdown508 <- function(inputId,label="",...){
  div(class="dropdown black-text", id = inputId,
      tags$button(type="button",
                  class="usa-accordion-button dropdown-toggle shiny-bound-input arrow-button",
                  'data-toggle'="dropdown",
                  'aria-expanded'="false", label),
      tags$ul(class="dropdown-menu dropdown-menu-form", 'aria-labelledby'=inputId,...)
  )
}

# From Shiny -- re-written in case shiny updated ---------------------------------

firstChoice <- function(choices) {
  if (length(choices) == 0L) 
    return()
  choice <- choices[[1]]
  if (is.list(choice)) 
    firstChoice(choice)
  else choice
}

selectOptions <- function (choices, selected = NULL) {
  html <- mapply(choices, names(choices), FUN = function(choice, label) {
    if (is.list(choice)) {
      sprintf("<optgroup label=\"%s\">\n%s\n</optgroup>", 
              htmlEscape(label, TRUE), selectOptions(choice, selected))
    }
    else {
      sprintf("<option value=\"%s\"%s>%s</option>", htmlEscape(choice, TRUE), 
              if (choice %in% selected) " selected" else "", htmlEscape(label))
    }
  })
  HTML(paste(html, collapse = "\n"))
}

choicesWithNames <- function (choices) {
  listify <- function(obj) {
    makeNamed <- function(x) {
      if (is.null(names(x))) 
        names(x) <- character(length(x))
      x
    }
    res <- lapply(obj, function(val) {
      if (is.list(val)) 
        listify(val)
      else if (length(val) == 1 && is.null(names(val))) 
        as.character(val)
      else makeNamed(as.list(val))
    })
    makeNamed(res)
  }
  choices <- listify(choices)
  if (length(choices) == 0) return(choices)
  choices <- mapply(choices, names(choices), FUN = function(choice, name) {
    if (!is.list(choice)) 
      return(choice)
    if (name == "") 
      stop("All sub-lists in \"choices\" must be named.")
    choicesWithNames(choice)
  }, SIMPLIFY = FALSE)
  missing <- names(choices) == ""
  names(choices)[missing] <- as.character(choices)[missing]
  choices
}

