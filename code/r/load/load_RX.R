year <- .year.

# Load RX file
  RX <- read.xport(".PUFdir./.RX..ssp")
  
  if(year <= 2001) RX <- RX %>% mutate(VARPSU = VARPSU.yy., VARSTR = VARSTR.yy.)
  if(year <= 1998) RX <- RX %>% rename(PERWT.yy.F = WTDPER.yy.)

# For 1996-2013, merge with RX Multum Lexicon Addendum files
  if(year <= 2013) {
    Multum <- read.xport(".PUFdir./.Multum..ssp")
    RX <- RX %>%
      select(-starts_with("TC"), -one_of("PREGCAT", "RXDRGNAM")) %>%
      left_join(Multum, by = c("DUPERSID", "RXRECIDX"))
  }
  
# Merge with therapeutic class names ('tc1_names')
  RX <- RX %>%
    left_join(tc1_names, by = "TC1") %>%
    mutate(count = 1)
