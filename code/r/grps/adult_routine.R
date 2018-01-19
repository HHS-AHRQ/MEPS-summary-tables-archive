# Ability to schedule a routine appt. (adults)
  FYC <- FYC %>%
    mutate(adult_routine = recode_factor(
      ADRTWW42, .default = "Missing",.freq.))
