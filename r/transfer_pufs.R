# install.packages('dplyr')
# install.packages('devtools')

library(dplyr)
library(devtools)

install_github("e-mitchell/meps_r_pkg/MEPS")
library(MEPS)

fnames = get_puf_names() %>% 
  select(-Year, -Old.Panel, -New.Panel) %>% 
  unlist(use.names = F) 

fnames = fnames[!fnames %in% c("","-")]

exdir = "/Users/emilymitchell/Desktop/MEPS"
#exdir = "C:/MEPS"

sapply(fnames, function(x) 
  try(download_ssp(x, dir = exdir, silent = T)))

#download_ssp('h26bf1', dir = exdir,force=T)
