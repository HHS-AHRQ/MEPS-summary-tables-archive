# Difficulty receiving needed care
  FYC <- FYC %>%
    mutate(delay_MD = (MDUNAB42 == 1|MDDLAY42==1)*1,
           delay_DN = (DNUNAB42 == 1|DNDLAY42==1)*1,
           delay_PM = (PMUNAB42 == 1|PMDLAY42==1)*1,
           delay_ANY = (delay_MD|delay_DN|delay_PM)*1)
