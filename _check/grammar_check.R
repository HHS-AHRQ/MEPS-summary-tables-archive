
setwd("C:/Users/emily.mitchell/Desktop/GitHub/meps_JS")

apps = c('use', 'ins', 'care', 'cond', 'pmed')

cleanFun <- function(htmlString) {
  return(gsub("<.*?>", "", htmlString))
}

out <- NULL
for(app in apps) {
  info <- infoList[[app]] 
  out <- paste(out, info$preview, info$description, info$instructions1, info$instructions2, sep = "\n")
}
out <- out %>% cleanFun
write(out, file = "all_infos.txt")


all_notes <- notes %>% unlist %>% paste(collapse = "\n") %>% cleanFun 
all_notes %>% writeLines
write(all_notes, file = 'all_notes.txt')

# Paste text files into word, run spell check
