# How often doctor spent enough time (children)
  FYC <- FYC %>%
    mutate(child_time = recode_factor(
      CHPRTM42, .default = "Missing", .missing = "Missing", .freq.))
