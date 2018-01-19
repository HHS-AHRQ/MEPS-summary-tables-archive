# Reason for difficulty receiving needed dental care
  FYC <- FYC %>%
    mutate(delay_DN  = (DNUNAB42 == 1 | DNDLAY42 == 1)*1,
           afford_DN = (DNDLRS42 == 1 | DNUNRS42 == 1)*1,
           insure_DN = (DNDLRS42 %in% c(2,3) | DNUNRS42 %in% c(2,3))*1,
           other_DN  = (DNDLRS42 > 3 | DNUNRS42 > 3)*1)
