
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


run_tables <- function(appKey, year_list) {
  
  loadPkgs %>% run
  
  tbl_dir <- sprintf("data_tables/%s", appKey)
  dir.create(tbl_dir)
  
  load_fyc <- loadFYC[[appKey]]
  
  row_grps <- rowGrps_R[[appKey]]
  col_grps <- colGrps_R[[appKey]]
  stats <- names(statCode[[appKey]]) # need statCode to get n and n_exp
  

  for(year in year_list) {
    
  ## For each year, load needed files and create subgroups before looping over
  ## stats, rows, and cols. This will save time in processing.
    
    done_file = sprintf("%s/%s/_DONE.Rdata",tbl_dir,year)
    if(file.exists(done_file)) next
    
    dir.create(sprintf('%s/%s',tbl_dir,year))
    
    yr <- substring(year, 3, 4)
    yb <- substring(year - 1, 3, 4)
    ya <- substring(year + 1, 3, 4)
    
    # Subgroups to keep on FYC file
      sgComma = c(row_grps, col_grps) %>% unique %>% unlist %>% 
        pop(c("event", "event_v2X", "sop", "event_sop", "Condition")) %>%
        paste(collapse = ",")
    
    # Substitution list for rsub 
      subList = list(get_puf_names(year, web = F), 
                     PUFdir = mydir, 
                     subgrps = sgComma, 
                     year = year, yy = yr, ya = ya, yb = yb)
    
    # Load FYC file
      load_fyc %>% rsub(subList) %>% run
  
    # Create all subgroups in FYC file
      load_grps <- c(row_grps, col_grps) %>% unique
      load_grps <- load_grps[load_grps %in% names(grpCode)]
      if(appKey == 'hc_use') load_grps <- c(load_grps, "event_sop")
      
      for(sg in load_grps)
        grpCode[[sg]] %>% rsub(subList) %>% run
    
    # Load event files (if needed)
      loadCode[[appKey]] %>% unlist %>% unique %>% rsub(subList) %>% run
    
    # Define all design objects for svyby
      dsgnCode[[appKey]] %>% unlist %>% unique %>% rsub(subList) %>% run
    
      
    for (stat in stats) {  print(stat)
      outfile <- sprintf("%s/%s.csv", year, stat)
      
      rG <- row_grps
      cG <- col_grps
      
      
      # #### TEMPORARY FOR TESTING ##########
      # lrG <- length(rG)
      # lcG <- length(cG)
      # 
      # r_start <- max(lrG - 4, 1)
      # c_start <- max(lcG - 4, 1)
      # 
      # rG <- rG[r_start:lrG]
      # cG <- cG[c_start:lcG]
      #   
      # 
      #####################################
      
      
      # Running 'by ~ event_v2X' only works for meanEVT, totEVT
      if(!stat %in% c("meanEVT", "totEVT")) {
        rG <- rG %>% pop("event_v2X")
        cG <- cG %>% pop("event_v2X")
      }
      
      for(row in rG) { 
        for(col in cG) {
          
          # Skip if already run
            row2 = row %>% gsub("_v2X","",.) %>% gsub("_v3X","",.)
            col2 = col %>% gsub("_v2X","",.) %>% gsub("_v3X","",.)
            if(row2 == col2 & row2 != 'ind') next
            
            if( done(outfile, dir = tbl_dir, rowGrp = row, colGrp = col) |
                done(outfile, dir = tbl_dir, rowGrp = col, colGrp = row)) next
          
          # Get svyby statement for row, col, stat
            grps <- c(row, col)
            
            is_evt <- 'event' %in% grps
            is_sop <- 'sop' %in% grps
            
            grpKey <- case_when(
              appKey == "hc_care" ~ col,
              appKey == "hc_ins" ~ col,
              appKey == "hc_pmed" ~ row,
              is_evt & is_sop ~ "event_sop",
              is_sop ~ "sop",
              is_evt ~ "event",
              TRUE   ~ "demo"
            )
          
            stat_code <- getItem(statCode, keys = c(appKey, stat, grpKey))
          
          # Rsub for row, col
            subgrps <- 
              c(grps, 'ind') %>% 
              unique %>% 
              pop("sop", "event", "Condition")
            
            byGrps <- 
              grps[c("row" %in% byVars[[appKey]], 
                     "col" %in% byVars[[appKey]])] %>%
              pop('ind', 'event', 'sop') %>%
              unique
            
            if(length(byGrps) == 0) byGrps <- 'ind'
            
            codeText <- stat_code %>% 
              rsub(by = paste0(byGrps, collapse = " + ")) %>% 
              rsub(subList) %>%
              gsub("print\\(", "#print\\(",.) 
            
            codeText %>% run
      
          
          ## Standardize results ---------------------------------
          
            # big number of lines in code for event / sop loops
            nlines <- gregexpr("\n",codeText)[[1]] %>% length
            if(nlines > 2 & (is_evt | is_sop)) {
         
              res <- list()
              for(nm in names(results)) {
                temp <- results[[nm]]
                
                # Extract event, sop name
                ev <- substr(nm, 1, 3)
                sp <- substr(nm, 4, 6)
                if(ev %>% startsWith("RX")) {
                  ev <- "RX"
                  sp <- substr(nm, 3, 5)
                }
                
                if(stat %in% c("meanEVT", "totEVT")){
                  temp <- temp %>% mutate(sop = substr(nm, 1, 2))
                } else if(sp != "") {
                  temp <- temp %>% mutate(sop = sp)
                }
                
                if(!stat %in% c("meanEVT", "totEVT")) 
                  temp <- temp %>% mutate(event = ev)
                
                gatherW = (stat == 'avgEVT' & is_sop)
                res[[nm]] <- temp %>% standardize(stat, row, col, gather = gatherW)
              }
              out <- bind_rows(res)
              
            } else {

              out <- results %>% 
                standardize(stat, rowGrp = row, colGrp = col) 
            }
            
           print(out %>% head(10)) # take a peek
          
          ## Save to csv file -------------------------------------------------
            update.csv(out, file = outfile, dir = tbl_dir)
            rm(out, results) # needed to work inside function
            
        } # col in colGrps
      } # row in rowGrps
    } # stat in stats
    
    all_done = TRUE
    save(all_done, file = done_file)
  }
} # end run_tables function

