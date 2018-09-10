# Usual source of care
  FYC <- FYC %>%
    mutate(usc = ifelse(HAVEUS42 == 2, 0, LOCATN42)) %>%
    mutate(usc = recode_factor(usc, .default = "Missing", .missing = "Missing", 
      "0" = "No usual source of health care",
      "1" = "Office-based",
      "2" = "Hospital (not ER)",
      "3" = "Emergency room"))
