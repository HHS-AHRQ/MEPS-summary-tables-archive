# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(dplyr)
library(tidyr)
library(survey)

source("functions.R")
source("dictionaries.R")
source("codes.R", chdir = T)

#appKey = 'ins' ; year_list = 1996:2015; year = 1996;
#appKey = 'cond'; year_list = 1996:2015; year = 2003;
#appKey = 'pmed'; year_list = 2013:2015; year = 2014;
#appKey = 'care'; year_list = 2002:2015; year = 2002;
#appKey = 'use' ; year_list = 1996:2015; year = 2015; 

loadPkgs[['R']] %>% run

mydir = "/Users/emilymitchell/Desktop/MEPS"
# mydir = "C:/MEPS"

run_tables <- function(appKey, year_list) {
  
  tbl_dir <- sprintf("../tables/%s", appKey)
  dir.create(tbl_dir)
  
  stats   <- names(statCode[[appKey]][['R']])
  subgrps <- c(rowGrps_R[[appKey]], colGrps_R[[appKey]]) %>% unique
    
    # extended_grps %>% unlist(use.names = F) %>% 
    # add_v2X %>% add_v3X %>% append(c('racesex', 'event_sop'))

  for(year in year_list) {
    done_file = sprintf("%s/%s/_DONE.Rdata",tbl_dir,year)
    #if(file.exists(done_file)) next
      
    dir.create(sprintf('%s/%s',tbl_dir,year))
    yr <- substring(year, 3, 4)
    yb <- substring(year - 1, 3, 4)
    ya <- substring(year + 1, 3, 4)
    
    sgComma = subgrps %>% unlist %>% 
      pop(c("event", "event_v2X", "sop", "event_sop", "Condition")) %>%
      paste(collapse = ",")

    subList = list(get_puf_names(year, web = F), 
                   PUFdir = mydir, 
                   subgrps = sgComma, 
                   year = year, yy = yr, ya = ya, yb = yb)
    
    loadFYC[[appKey]][['R']] %>% rsub(subList) %>% run

    load_grps <- c(rowGrps_R[[appKey]], colGrps_R[[appKey]]) %>% unique
    load_grps <- load_grps[load_grps %in% names(grpCode[['R']])]
    if(appKey == 'use') load_grps <- c(load_grps, "event_sop")
    
    for(sg in load_grps)
        grpCode[['R']][[sg]] %>% rsub(subList) %>% run
  
    loadCode[[appKey]][['R']] %>% unlist %>% unique %>% rsub(subList) %>% run
    dsgnCode[[appKey]][['R']] %>% unlist %>% unique %>% rsub(subList) %>% run
  
    for (stat in stats) {  print(stat)
      outfile <- sprintf("%s/%s.csv", year, stat)
      
      rG <- rowGrps_R[[appKey]] #[1:min(4,length(rowGrps_R[[appKey]]))]
      cG <- colGrps_R[[appKey]] #[1:min(4,length(colGrps_R[[appKey]]))]

      if(!stat %in% c("meanEVT", "totEVT")) {
        rG <- rG %>% pop("event_v2X")
        cG <- cG %>% pop("event_v2X")
      }

      for(row in rG) { 
        for(col in cG) {
          
          row2 = row %>% gsub("_v2X","",.) %>% gsub("_v3X","",.)
          col2 = col %>% gsub("_v2X","",.) %>% gsub("_v3X","",.)
          if(row2 == col2 & row2 != 'ind') next
          
          if( done(outfile, dir = tbl_dir, rowGrp = row, colGrp = col) |
              done(outfile, dir = tbl_dir, rowGrp = col, colGrp = row)) next

          code <- statCode[[appKey]][['R']][[stat]]
          
          grps   <- c(row, col)
          is_evt <- 'event' %in% c(row2, col2)
          is_sop <- 'sop' %in% c(row2, col2)
          
          rcKey = ifelse(is_evt & is_sop, 'event_sop', grps[which(grps %in% names(code))[1]])
          if(is.na(rcKey)) rcKey <- "demo"
          
          codeC <- code[[rcKey]]

          by <- switch(byVars[[appKey]], 
                'row' = row, 
                'col' = col, 
                'rc' = c(row, col)) %>%
            pop('ind', 'event', 'sop') %>% 
            paste0(collapse = " + ")
          
          if(by == "") by <- 'ind'
          
          # big number of lines in code for event / sop loops
          nlines <- gregexpr("\n",codeC)[[1]] %>% length
          if(nlines > 2 & (is_evt | is_sop)) {
            codeC %>% 
              rsub("yy" = yr, "by" = by) %>% 
              gsub("print\\(", "#print\\(",.) %>%
              run  
            
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
            sprintf("results = %s", codeC) %>% rsub("yy" = yr, "by" = by) %>% run  
            out <- results %>% 
              standardize(stat, rowGrp = row, colGrp = col) 
          }
          
          print(out %>% head(10))
         
          update.csv(out, file = outfile, dir = tbl_dir)
          rm(out, results) # needed to work inside function

        } # col in colGrps
      } # row in rowGrps
    } # stat in stats

    all_done = TRUE
    save(all_done, file = done_file)
  }
} # end run_tables function


# run_tables(appKey = 'care', year_list = c(2002,2015))
# run_tables(appKey = 'cond', year_list = c(1996,2015))
# run_tables(appKey = 'use',  year_list = c(1996,2015))
# run_tables(appKey = 'pmed', year_list = c(2013,2015))
# run_tables(appKey = 'ins',  year_list = c(1996,2015))

run_tables(appKey = 'ins',  year_list = 1996:2015)
run_tables(appKey = 'pmed', year_list = 2013:2015)
run_tables(appKey = 'care', year_list = 2002:2015)
run_tables(appKey = 'cond', year_list = 1996:2015)


run_tables(appKey = 'use',  year_list = 1996:2015)

run_tables(appKey = 'use',  year_list = 1996:2000)
run_tables(appKey = 'use',  year_list = 2010:2012)
run_tables(appKey = 'use',  year_list = 2013:2015)

run_tables(appKey = 'use',  year_list = 2001:2005)
run_tables(appKey = 'use',  year_list = 2006:2010)
run_tables(appKey = 'use',  year_list = 2011:2015)

  