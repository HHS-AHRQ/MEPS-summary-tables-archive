## WARNING!! THIS WILL OVERWRITE EXISTING TABLES -- DON'T SCREW IT UP 

library(dplyr)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

csv_only <- function(vec) vec[grepl('csv',vec)]

setwd("../build_hc_tables/data_tables/hc_care")

years <- list.files()
for(year in years){
   files = list.files(as.character(year)) %>% csv_only
   unlink(sprintf("%s/_DONE.Rdata",year))
   
   print(c(year, files))
   
  
   for(file in files) {
     fname = sprintf("%s/%s", year, file)
     print(fname)
     
     tab <- read.csv(fname)
     
     tab <- tab %>% filter(colGrp != "adult_nosmok")
     
     write.csv(tab, file = fname, row.names = F)
   
   }
   
}
    