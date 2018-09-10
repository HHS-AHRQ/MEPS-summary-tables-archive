# Children receiving dental care
  FYC <- FYC %>%
    mutate(
      child_2to17 = (1 < AGELAST & AGELAST < 18),
      child_dental = ((DVTOT.yy. > 0) & (child_2to17==1))*1,
      child_dental = recode_factor(
        child_dental, .default = "Missing", .missing = "Missing", 
        "1" = "One or more dental visits",
        "0" = "No dental visits in past year"))
