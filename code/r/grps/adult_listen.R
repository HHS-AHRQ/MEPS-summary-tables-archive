# How often doctor listened carefully (adults)
  FYC <- FYC %>%
    mutate(adult_listen = recode_factor(
      ADLIST42, .default = "Missing",.freq.))
