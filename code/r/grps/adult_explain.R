# How often doctor explained things (adults)
  FYC <- FYC %>%
    mutate(adult_explain = recode_factor(
      ADEXPL42, .default = "Missing",.freq.))
