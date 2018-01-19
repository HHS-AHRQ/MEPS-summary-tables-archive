setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

require(dplyr)
require(RSelenium)

source("../../r/functions.R")
 
# Function to write codes, after selecting 'Code' / 'Cross-sectional
  write_codes = function(app) {
    
    # Find dropdowns and get options
        
      get_names = function(x) x$getElementAttribute('value')[[1]]
        
      stat_select = rD$findElement(using = 'id', value = 'stat')
      row_select  = rD$findElement(using = 'id', value = 'rowGrp')
      col_select  = rD$findElement(using = 'id', value = 'colGrp')
      year_select = rD$findElement(using = 'id', value = 'year')
      code_select = rD$findElement(using = 'id', value = 'code-language')
      
      stat_options = stat_select$findChildElements(using = 'tag name', value = 'option')
      row_options  = row_select$findChildElements(using = 'tag name', value = 'option')
      col_options  = col_select$findChildElements(using = 'tag name', value = 'option')
      year_options = year_select$findChildElements(using = 'tag name', value = 'option')
      code_options = code_select$findChildElements(using = 'tag name', value = 'option')
      
      stat_names = sapply(stat_options, get_names)
      col_names = sapply(col_options, get_names)
      row_names = sapply(row_options, get_names)
      year_names = sapply(year_options, get_names)
     
       
    # Generate permutations of tests -- see 'Code Testing (evernote)'
    
      check <- list(); set.seed(4321);
        
      # Use app  
      if(app == 'use') {
      
        demo_names = c(col_names, row_names) %>% unique %>% pop(c('event', 'sop'))
        
        # no. Stat (9)    Grps (14)     Years (20)
        # 1   (All)       Event x SOP   1996, 1999, 2011, 2015
        # 2   (All)       Event x [grp] [year]
        # 3   (All)       SOP   x [grp] [year]
        # 4   [stat]      ind   x race  1996, 2002, 2012
        #     [stat]      ind   x educ  1998, 2004, 2012
        #     [stat]      ind   x ins   1996, 2010, 2011
        # 5   avgEVT      ind   x (all) 1996, 2015
        # 6   medEXP      [grp] x [grp] [year]  (x5)
        # 7   [stat]      [grp] x [grp] [year]  (x9)
        # 8   [use stat]  [grp] x [grp] (all)   (x20)
        
        
        check[[1]] = expand.grid(stat = stat_names, row = 'event', col = 'sop', year = c('1996', '1999', '2011', '2015'), stringsAsFactors = F)
        
        check[[2]] = expand.grid(stat = stat_names, row = 'event', stringsAsFactors = F)
        check[[2]]$col = sample(demo_names, 9)
        check[[2]]$year = sample(year_names, 9)
        
        check[[3]] = expand.grid(stat = stat_names, row = 'sop', stringsAsFactors = F)
        check[[3]]$col = sample(demo_names, 9)
        check[[3]]$year = sample(year_names, 9)
        
        check[[4]] = 
          bind_rows(
            expand.grid(row = 'ind', col = 'race',      year = c('1996', '2002', '2012'), stringsAsFactors = F),
            expand.grid(row = 'ind', col = 'education', year = c('1998', '2004', '2012'), stringsAsFactors = F),
            expand.grid(row = 'ind', col = 'insurance', year = c('1996', '2010', '2011'), stringsAsFactors = F)
          )
        check[[4]]$stat = sample(stat_names, 9)
        
        check[[5]] = expand.grid(stat = 'avgEVT', row = 'ind', col = demo_names, year = c('1996', '2015'), stringsAsFactors = F)
        
        samp_grps6 = sample(demo_names %>% pop('ind'), 10)
        check[[6]] = data.frame(stat = 'medEXP', row = samp_grps6[1:5], col = samp_grps6[6:10], year = sample(year_names, 5))
       
        check[[7]] = data.frame(
          stat = sample(stat_names, 9), 
          row  = sample(demo_names, 9), 
          col  = sample(demo_names, 9),  
          year = sample(year_names, 9))
        
        check[[8]] = data.frame(
          stat = sample(c("avgEVT","meanEVT","totEVT"), 20, replace = T),
          row = sample(demo_names, 20, replace = T),
          col = sample(demo_names, 20, replace = T),
          year = year_names
        )
    
      } else if (app == 'ins') {
        
        # no. Stat (2)  Row (12)  Col (3)   Years (20)
        # 1   (All)     [grp]     (all)     (all)
       
        check[[1]] = expand.grid(stat = stat_names, col = col_names, year = year_names, stringsAsFactors = F)
        check[[1]]$row = sample(row_names, nrow(check[[1]]), replace = T)
        
      } else if (app == 'care') {
    
        # no. Stat (2)  Row (12)  Col (27)      Years (14)
        # 1   (All)     [grp]     (all)         [year]
        # 2   [stat]    [grp]     usc           2002, 2008
        # 3   [stat]    [grp]     adult_nosmok  2002, 2012
        # 4   [stat]    [grp]     diab_chol     2007, 2008
        # 5   [stat]    [grp]     diab_foot     2007, 2008
        # 6   [stat]    [grp]     diab_flu      2007, 2008
        # 7   [stat]    [grp]     diab_eye      2002, 2015
        # 8   [stat]    [grp]     (all)         [year] (x2)
        
        check[[1]] = expand.grid(stat = stat_names, col = col_names, stringsAsFactors = F)
        check[[1]]$row = sample(row_names, nrow(check[[1]]), replace = T)
        check[[1]]$year = '2002'
        
        check[[2]] = expand.grid(stat = stat_names, col = col_names, stringsAsFactors = F)
        check[[2]]$row = sample(row_names, nrow(check[[1]]), replace = T)
        check[[2]]$year = sample(year_names %>% pop('2002'), nrow(check[[1]]), replace = T)
        
        check[[3]] = data.frame(
          stat = sample(stat_names, 2, replace = T),
          row  = sample(row_names, 2, replace = T),
          col  = 'usc',
          year = c('2003', '2008')
        )
        
        check[[4]] = data.frame(
          stat = sample(stat_names, 2, replace = T),
          row  = sample(row_names, 2, replace = T),
          col  = 'adult_nosmok',
          year = c('2003', '2012')
        )
        
        check[[5]] = data.frame(
          stat = sample(stat_names, 2, replace = T),
          row  = sample(row_names, 2, replace = T),
          col  = 'diab_eye',
          year = c('2003', '2015')
        )
        
        check[[6]] = expand.grid(col = c("diab_chol", "diab_foot", "diab_flu"), year = c("2007", "2008"), stringsAsFactors = F)
        check[[6]]$stat = sample(stat_names, nrow(check[[6]]), replace = T)
        check[[6]]$row = sample(row_names, nrow(check[[6]]))
        
      } else if (app == 'cond') {
        
        # no. Stat (4)  Row (1)   Col (14)    Years (20)
        # 1   (All)     (cond)    Event       [year] (x2)
        # 2   (All)     (cond)    SOP         [year] (x2)
        # 3   (All)     (cond)    [grp]       [year] (x2)
        # 4   [stat]    (cond)    Event       (all)
        # 5   [stat]    (cond)    SOP         (all)
        # 6   [stat]    (cond)    [grp]       (all)
      
        check[[1]] = data.frame(
          stat = rep(stat_names, 2),
          row = 'Condition',
          col = 'event',
          year = sample(year_names, 8)
        )
        
        check[[2]] = data.frame(
          stat = rep(stat_names, 2),
          row = 'Condition',
          col = 'sop',
          year = sample(year_names, 8)
        )
        
        check[[3]] = data.frame(
          stat = rep(stat_names, 2),
          row = 'Condition',
          col = sample(col_names, 8),
          year = sample(year_names, 8)
        )
        
        check[[4]] = data.frame(
          stat = sample(stat_names, 20, replace = T),
          row = 'Condition',
          col = 'event',
          year = year_names
        )
        
        check[[5]] = data.frame(
          stat = sample(stat_names, 20, replace = T),
          row = 'Condition',
          col = 'sop',
          year = year_names
        )
        
        check[[6]] = data.frame(
          stat = sample(stat_names, 20, replace = T),
          row = 'Condition',
          col = sample(col_names, 20, replace = T),
          year = year_names
        )
     
      } else if (app == 'pmed') {
        
        # no. Stat (3)  Row (2)   Col (1)   Years (3)
        # 1   (All)     TC1name   ind       (all)
        # 2   (All)     RXDRGNAM  ind       (all)  
        
        check[[1]] = expand.grid(stat = stat_names, row = 'TC1name', col = 'ind', year = year_names)
        check[[2]] = expand.grid(stat = stat_names, row = 'RXDRGNAM', col = 'ind', year = year_names)
        
      }
      
      CHECKS = bind_rows(check) # 101 total
      
      # Randomly shuffle row and col -- use app only
      if(app == 'use') {
        CHECKS = CHECKS %>% 
          mutate(
            select_rc = sample(1:2, nrow(CHECKS), replace = T),
            newrow = ifelse(select_rc == 1, row, col),
            newcol = ifelse(select_rc == 1, col, row),
            row = newrow,
            col = newcol)
      }
      
     
    ## Remove old codes (CAUTION!!)
      # unlink(app, recursive = T)
      dir.create(app)
      dir.create(paste0(app,"/r_codes"))
      dir.create(paste0(app,"/sas_codes"))
      
      unlink(paste0(app,"/sas_results"), recursive = T)
      dir.create(paste0(app, "/sas_results"))
      
                              
    # Select options and output code (loop)
     
    i = 1
    N = nrow(CHECKS)
    
    for(i in 1:N) {  cat('\n',i, 'of', N); 
      stat_name = CHECKS$stat[i]
      year_name = CHECKS$year[i]
      row_name = CHECKS$row[i]
      col_name = CHECKS$col[i]
      
      filename = sprintf('%s_%s_%s_%s', stat_name, row_name, col_name, year_name)
      
      stat_options[[which(stat_names == stat_name)]]$clickElement()
      year_options[[which(year_names == year_name)]]$clickElement()
      if(app != 'pmed') col_options[[which(col_names == col_name)]]$clickElement() # col is hidden in pmed ('ind' only)
      if(app != 'cond') row_options[[which(row_names == row_name)]]$clickElement() # row is hidden in conditions app ('condition' only)
      
      # Switch to R code and write code to file
      code_options[[1]]$clickElement()
      code_text = rD$findElement(using = 'id', value = 'code')$getElementText()[[1]]
      write(code_text, file = sprintf('%s/r_codes/%s.R', app, filename))

      # Switch to SAS code and write code to file
      code_options[[2]]$clickElement()
      code_text = rD$findElement(using = 'id', value = 'code')$getElementText()[[1]]
      write(code_text, file = sprintf('%s/sas_codes/%s.sas', app, filename))
    }
      
}

  
# Initialize remote driver
  remDr <- rsDriver(remoteServerAddr = "localhost", 
                    port = 4444L,
                    browser = "chrome")
  
  rD <- remDr$client
  
  rD$getStatus()
  
# Set app
# app <- 'use'
# app <- 'ins'
# app <- 'care'
# app <- 'cond'
app <- 'pmed'

# Navigate to app
#rD$navigate(sprintf("https://www.ahrq-meps.com/shiny/meps_JS/mepstrends/hc_%s/",app))
rD$navigate(sprintf("http://meps.uat.s-3.net/mepstrends/hc_%s/index.html", app))


### STOP !!!


## HERE!! -- select 'code', 'cross-sectional'
write_codes(app)


# ## These aren't working so good on windows...     
#   # Switch to code tab
#   tabs = rD$findElement(using = 'id', value = 'tabs')
#   code_tab = tabs$findChildElements(using = 'tag name', value = 'li')
#   code_tab[[3]]$clickElement()
#   
#   
#   # Switch to cross-sectional
#   data_view = rD$findElement(using = 'id', value = 'data-view')
#   cross_view = data_view$findChildElements(using = 'tag name', value = 'label')
#   cross_view[[3]]$clickElement()
  

## Later 
## -- verify that trends is the same code as cross-sectional with 'ind' group
## Use app: verify that 'switch rows/columns' gives same code


