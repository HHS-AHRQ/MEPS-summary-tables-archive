# Adults advised to quit smoking
  if(year == 2002)
    FYC <- FYC %>% rename(ADNSMK42 = ADDSMK42)

  FYC <- FYC %>%
    mutate(
      adult_nosmok = recode_factor(ADNSMK42, .default = "Missing", .missing = "Missing", 
        "1" = "Told to quit",
        "2" = "Not told to quit"))
