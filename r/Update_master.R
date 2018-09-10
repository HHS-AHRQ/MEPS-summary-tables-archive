
# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

combine_tables <- function(tbls_dir) {
  tb <- list()
  all_files <- list.files(tbls_dir)
  csv_only <- all_files[all_files %>% endsWith(".csv")]
  for(csv in csv_only){
    cat(csv,"..")
    dt <- read.csv(sprintf("%s/%s", tbls_dir, csv), stringsAsFactors = F)
    year <- csv %>% gsub("DY","",.) %>% gsub("\\.csv","",.)
    
    tb[[csv]] <- dt %>%
      mutate(Year = as.numeric(year),
             coef = as.character(coef), 
             se = as.character(se))
  }
  return(bind_rows(tb))
}

all_apps <- list.files("../formatted_tables")

apps <- all_apps[all_apps %>% startsWith("hc_")]

for(app in apps) {
  cat("\n\n",app,"\n")
  folder <- sprintf("../formatted_tables/%s/", app)
  file <- paste0(folder, app, ".Rdata")

  MASTER_TABLE <- combine_tables(folder)
  save(MASTER_TABLE, file = file)
}