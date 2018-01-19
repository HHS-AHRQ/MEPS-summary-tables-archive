# How often doctor showed respect (children)
  FYC <- FYC %>%
    mutate(child_respect = recode_factor(
      CHRESP42, .default = "Missing",.freq.))
