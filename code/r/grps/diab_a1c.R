# Diabetes care: Hemoglobin A1c measurement
  FYC <- FYC %>%
    mutate(diab_a1c = ifelse(0 < DSA1C53 & DSA1C53 < 96, 1, DSA1C53)) %>%
    mutate(diab_a1c = replace(diab_a1c,DSA1C53==96,0)) %>%
    mutate(diab_a1c = recode_factor(diab_a1c, .default = "Missing",
      "1" = "Had measurement",
      "0" = "Did not have measurement",
      "-7" = "Don\'t know/Non-response",
      "-8" = "Don\'t know/Non-response",
      "-9" = "Don\'t know/Non-response",
      "-1" = "Inapplicable"))
