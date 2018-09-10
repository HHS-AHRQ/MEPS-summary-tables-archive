## This code will download all PUFs to local directory (mydir -- set in UPDATE.R)

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
fnames = fnames[fnames != "h01"] # 1996 PIT file only in ASCII format

for(dat in fnames) 
  download_ssp(dat, dir = mydir, silent = T)

#download_ssp('h26bf1', dir = mydir,force=T)

