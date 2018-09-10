# Ability to schedule a routine appt. (children)
  FYC <- FYC %>%
    mutate(child_routine = recode_factor(
      CHRTWW42, .default = "Missing", .missing = "Missing", .freq.))
