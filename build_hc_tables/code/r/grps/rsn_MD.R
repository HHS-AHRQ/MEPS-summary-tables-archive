# Reason for difficulty receiving needed medical care
  FYC <- FYC %>%
    mutate(delay_MD  = (MDUNAB42 == 1 | MDDLAY42 == 1)*1,
           afford_MD = (MDDLRS42 == 1 | MDUNRS42 == 1)*1,
           insure_MD = (MDDLRS42 %in% c(2,3) | MDUNRS42 %in% c(2,3))*1,
           other_MD  = (MDDLRS42 > 3 | MDUNRS42 > 3)*1)
