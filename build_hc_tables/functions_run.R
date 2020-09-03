
# Run functions -----------------------------------------------------------------

p <- paste0

# NEW! standardize function
stdize <- function(df, row, stat) {
  
  # Convert from wide to long
    dfX <- df %>%
      gather(key = colLevels, value = stat, -row) %>%
      filter(!grepl("FALSE", colLevels)) %>%
      mutate(colLevels = gsub(" > 0TRUE","",colLevels))
    
  # Split coefs and ses, then re-join
    coefs <- dfX %>% filter(!grepl("se.",colLevels, fixed = T))
    ses <- dfX %>% filter(grepl("se.", colLevels, fixed = T)) %>%
      mutate(colLevels = gsub("se.","",colLevels, fixed = T)) %>%
      rename(se = stat)
    
    out <- full_join(coefs, ses)
  
  out %>% setNames(c("rowLevels", "colLevels", stat, paste0(stat, "_se")))
}

update.csv <- function(add, file, dir){
  add <- add %>% 
    select(one_of("rowGrp", "colGrp", "rowLevels", "colLevels", colnames(.)))
  
  init = !(file %in% list.files(dir, recursive=T))
  fileName <- sprintf("%s/%s", dir, file) %>% gsub("//","/",.)
  write.table(add, file = fileName, append = (!init), sep = ",", col.names = init, row.names = F)
}



# done <- function(outfile,...,dir="/"){
#   if(!outfile %in% list.files(dir,recursive=T)) return(FALSE)
#   
#   df <- read.csv(paste0(dir,"/",outfile))
#   chk <- list(...)
#   for(i in 1:length(chk)){
#     name=names(chk)[i]
#     value=chk[[i]]
#     df <- df %>% filter_(sprintf("%s=='%s'",name,value))
#   }
#   is.done = (nrow(df)>0)
#   if(is.done) print('skipping')
#   return(is.done)
# }

