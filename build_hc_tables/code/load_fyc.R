FYC_orig <- read_MEPS(year = year, type = "FYC")

FYC <- FYC_orig %>% mutate(ind = "Total")
colnames(FYC) <- colnames(FYC) %>% gsub(yr,"",.)

if(year <= 1998) FYC <- FYC %>% rename(PERWTF = WTDPER)