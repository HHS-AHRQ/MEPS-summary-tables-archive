# Ability to schedule appt. for illness or injury (adults)
  FYC <- FYC %>%
    mutate(adult_illness = recode_factor(
      ADILWW42, .default = "Missing",.freq.))
