# How often doctor explained things (children)
  FYC <- FYC %>%
    mutate(child_explain = recode_factor(
      CHEXPL42, .default = "Missing", .missing = "Missing", .freq.))
