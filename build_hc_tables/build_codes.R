setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(dplyr)

source("../r/functions.R")

# ------------------------------------------------------------

apps <- c("hc_use", "hc_care", "hc_cond", "hc_pmed", "hc_ins")

for(lang in c("r", "sas")) { print(lang)
  
  source(sprintf("codelist_%s.R", lang))
  
  for(appKey in apps) { print(appKey)
    dir = sprintf("../mepstrends/%s/json/code/%s/", appKey, lang)
    dir.create(dir, recursive = T)
    
    
    load_pkgs <- loadPkgs
    load_fyc <- loadFYC[[appKey]]
  
    row_grps <- rowGrps[[appKey]] %>% unlist
    col_grps <- colGrps[[appKey]] %>% unlist
    stats <- statList[[appKey]] %>% unlist
    
    for(row in row_grps) {
      for(col in col_grps) {
        
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
        
        for(stat in stats) {
          
          # Get group code based on row, col (and stat)
            is_evt_stat <- stat %in% c("meanEVT", "avgEVT", "totEVT")
            
            row_code <- grpCode[[row]]
            col_code <- grpCode[[col]]
            
            # Conditions app doesn't need the 'group' code for event and sop,
            #  since only event files are used
            if(row %in% c("event", "sop") & (is_evt_stat | appKey == "hc_cond")) row_code <- ""
            if(col %in% c("event", "sop") & (is_evt_stat | appKey == "hc_cond")) col_code <- ""
            
            grp_code <- c(col_code, row_code) %>% unique %>% paste0(collapse = "\n")
            
            if(is_sop & is_evt & !is_evt_stat) grp_code <- grpCode[['event_sop']]
              
            
          # Combine codes into text string
            load_code <- getItem(loadCode, keys = c(appKey, stat))
            dsgn_code <- getItem(dsgnCode, keys = c(appKey, stat, grpKey))
            stat_code <- getItem(statCode, keys = c(appKey, stat, grpKey))
       
            codeText <- paste(
              load_pkgs, load_fyc, grp_code,
              load_code, dsgn_code, stat_code, sep = "\n")
        
            
          # Rsub (year and filenames should be subbed in em.js)
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

            codeText <- codeText %>% rsub(
              PUFdir = "C:/MEPS",
              subgrps = subgrps %>% paste0(collapse = ","),
              by = paste0(byGrps, collapse = " + ")) 

          # For R code, add 'print(results)' at bottom
            if(lang == "r") {
              codeText <- codeText %>% paste0("\nprint(results)")
            }
            
          # SAS
            
            fmt <- paste(byGrps, paste0(byGrps, "."), collapse = " ")
            gp <- paste0(byGrps, collapse = " ")
            
            codeText <- codeText %>% rsub(
              PUFdir = "C:\\\\MEPS",
              fmt = fmt,
              format = paste("FORMAT",fmt),
              domain = paste0(byGrps, collapse = "*"),
              gp = gp,
              where = sprintf("and %s ne .", gp),
              type = 'sas')
          
          # formatting
            codeText <- codeText %>%
              gsub("\n\n\n\n", "\n\n", .) %>%
              gsub("\n\n\n", "\n\n", .) %>%
              gsub("\t", "  ", .)
            
          # Write to file
            fname <- sprintf("%s__%s__%s__.%s", stat, row, col, lang)
            write(codeText, file = paste0(dir, fname))
            
        }
  
      } # end col in rowGrps
    } # end row in rowGrps
    
  } # end appKey in apps

} # end for lang in "r", "sas"


