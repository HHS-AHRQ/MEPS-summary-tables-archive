
pop <- function(vec, ...) vec[!vec %in% unlist(list(...))]

add_v2X <- function(names) names %>% append(c('agegrps_v2X', 'insurance_v2X'))
add_v3X <- function(names) names %>% append(c('agegrps_v2X', 'agegrps_v3X'))

formatNum <- function(x, d) {
  xnum = x[!is.na(x)]
  dnum = d[!is.na(x)]

  spf <- paste0("%.",dnum,"f")
  fm_digits <- sprintf(spf, xnum)
  new_x <- prettyNum(fm_digits, big.mark = ",", preserve.width = "none")

  x[!is.na(x)] <- new_x
  return(x)
}

findKey <- function(nm, keys) {
  keys = as.character(keys)
  str = keys[sapply(keys, function(x) grepl(x, nm)) %>% which]
  if(length(str) == 0) return(NA)
  return(str)
}


getItem <- function(list, keys) {
  slist <- list
  default_code <- NULL

  for(i in 1:(length(keys)+1)) {

    if("DEFAULT" %in% names(slist)){
      default_code <- slist[["DEFAULT"]]
    }

    if(length(slist) == 1) {
      return(slist)
    } else if(keys[i] %in% names(slist)) {
      slist <- slist[[keys[i]]]
    }
  }

  return(default_code)
}



rm_v2 <- function(df){
df%>% mutate(rowGrp = rowGrp %>% gsub("_v2X","",.) %>% gsub("_v3X","",.),
             colGrp = colGrp %>% gsub("_v2X","",.) %>% gsub("_v3X","",.))
}

rm_na <- function(vec) {
  vec[!is.na(vec)]
}

rm_spec <- function(str) gsub("[^[:alnum:]]","",str) %>% tolower

readSource <- function(file,...,dir=".") {
  fileName <- sprintf("%s/%s",dir,file) %>% gsub("//","/",.)
  codeString <- readChar(fileName,file.info(fileName)$size)
  codeString <- codeString %>% gsub("\r","",.) # %>% gsub("\n","<br>",.)
  # codeString <- codeString %>% rsub(...) %>% gsub("\r","",.)
  codeString
}

run <- function(codeString,verbose=T){
  if(verbose) writeLines(codeString)
  eval(parse(text=codeString),envir=.GlobalEnv)
}

sentence_case <- function(str) {
  paste0(
    substring(str,1,1) %>% toupper,
    substring(str,2) %>% tolower
  )
}

switch_labels <- function(df){
  df %>%
    mutate(g1=rowGrp,g2=colGrp,l1=rowLevels,l2=colLevels) %>%
    mutate(rowGrp=g2,colGrp=g1,rowLevels=l2,colLevels=l1) %>%
    select(-g1,-g2,-l1,-l2)
}

reverse <- function(df) df[nrow(df):1,]

dedup <- function(df, rev = T){
  chk_vars <- c("Year", "stat", "rowGrp", "colGrp", "rowLevels", "colLevels")
  df_vars <- chk_vars[chk_vars %in% colnames(df)]
  if(rev) {
    out <- df %>%
      reverse %>%
      distinct_at(df_vars,.keep_all=TRUE) %>%
      reverse
  } else {
    out <- df %>%
      distinct_at(df_vars,.keep_all=TRUE)
  }
  return(out)
}


rsub <- function(string,...,type='r') {
  repl = switch(type,
                'r'='\\.%s\\.',
                'sas'='&%s\\.')

  sub_list = list(...) %>% unlist
  for(l in names(sub_list)){
    original <- sprintf(repl,l)
    replacement <- sub_list[l]
    string <- gsub(original,replacement,string)
  }
  return(string)
}

reorder_levels <- function(df,new_levels){
  orig_l1 = unique(df$levels)
  new_l1 = c(orig_l1[!orig_l1 %in% new_levels],new_levels)

  df %>%
    mutate(levels = factor(levels,levels=new_l1)) %>%
    arrange(levels) %>%
    mutate(levels = as.character(levels))
}
