# How often doctor spent enough time (adults)
  FYC <- FYC %>%
    mutate(adult_time = recode_factor(
      ADPRTM42, .default = "Missing", .missing = "Missing", .freq.))
