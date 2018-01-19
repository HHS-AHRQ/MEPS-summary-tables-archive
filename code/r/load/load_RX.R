# Load RX file and merge with therapeutic class names ('tc1_names')
  RX <- read.xport(".PUFdir./.RX..ssp") %>%
    left_join(tc1_names, by = "TC1") %>%
    mutate(count = 1)
