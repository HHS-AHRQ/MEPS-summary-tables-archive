
# Load RX file ----------------------------------------------------------------
RX <- read_MEPS(year = year, type = "RX") 
colnames(RX) <- colnames(RX) %>% gsub(yr,"",.)

if(year <= 1998) RX <- RX %>% rename(PERWTF = WTDPER)

# For 1996-2013, merge with RX Multum Lexicon Addendum files
if(year <= 2013) {
  Multum <- read_MEPS(year = year, type = "Multum") 
  RX <- RX %>%
    select(-starts_with("TC"), -one_of("PREGCAT", "RXDRGNAM")) %>%
    left_join(Multum, by = c("DUPERSID", "RXRECIDX"))
}

# Merge with therapeutic class names ('tc1_names')
RX <- RX %>%
  left_join(tc1_names, by = "TC1") %>%
  mutate(count = 1)