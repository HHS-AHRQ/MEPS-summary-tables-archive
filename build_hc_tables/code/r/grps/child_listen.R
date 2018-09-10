# How often doctor listened carefully (children)
  FYC <- FYC %>%
    mutate(child_listen = recode_factor(
      CHLIST42, .default = "Missing", .missing = "Missing", .freq.))
