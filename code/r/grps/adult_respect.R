# How often doctor showed respect (adults)
  FYC <- FYC %>%
    mutate(adult_respect = recode_factor(
      ADRESP42, .default = "Missing",.freq.))
