## WARNING!! THIS WILL OVERWRITE EXISTING TABLES -- DON'T SCREW IT UP 

library(dplyr)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

csv_only <- function(vec) vec[grepl('csv',vec)]

setwd("../tables/care")

years <- list.files()
for(year in years){
   files = list.files(as.character(year)) %>% csv_only
   #unlink(sprintf("%s/_DONE.Rdata",year))
   
   for(file in files) {
     fname = sprintf("%s/%s",year,file)
     
     print(fname)
     
     tab = read.csv(fname,stringsAsFactors = F)
     
     tab <- tab %>% 
       mutate(rowLevels = replace(rowLevels, 
                                  rowLevels == "Amer. Indian, AK Native, or mult. races",
                                  "Amer. Indian, Alaska Native, or mult. races"),
              colLevels = replace(colLevels, 
                                  colLevels == "Amer. Indian, AK Native, or mult. races",
                                  "Amer. Indian, Alaska Native, or mult. races")
              )
              
      print(tab$rowLevels %>% unique)
      print(tab$colLevels %>% unique)
              
     # 
     # tab <- tab %>% filter(!rowGrp %in% c("event", "sop"),
     #                       !colGrp %in% c("event", "sop")) 
     # 
     # write.csv(tab, file = fname, row.names = F)
   }

}
