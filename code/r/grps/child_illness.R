# Ability to schedule appt. for illness or injury (children)
  FYC <- FYC %>%
    mutate(child_illness = recode_factor(
      CHILWW42, .default = "Missing",.freq.))
