# Race / ethnicity
  # Starting in 2012, RACETHX replaced RACEX;
  if(year >= 2012){
    FYC <- FYC %>%
      mutate(white_oth=F,
        hisp   = (RACETHX == 1),
        white  = (RACETHX == 2),
        black  = (RACETHX == 3),
        native = (RACETHX > 3 & RACEV1X %in% c(3,6)),
        asian  = (RACETHX > 3 & RACEV1X %in% c(4,5)))

  }else if(year >= 2002){
    FYC <- FYC %>%
      mutate(white_oth=0,
        hisp   = (RACETHNX == 1),
        white  = (RACETHNX == 4 & RACEX == 1),
        black  = (RACETHNX == 2),
        native = (RACETHNX >= 3 & RACEX %in% c(3,6)),
        asian  = (RACETHNX >= 3 & RACEX %in% c(4,5)))

  }else{
    FYC <- FYC %>%
      mutate(
        hisp = (RACETHNX == 1),
        black = (RACETHNX == 2),
        white_oth = (RACETHNX == 3),
        white = 0,native=0,asian=0)
  }

  FYC <- FYC %>% mutate(
    race = 1*hisp + 2*white + 3*black + 4*native + 5*asian + 9*white_oth,
    race = recode_factor(race, .default = "Missing",
      "1" = "Hispanic",
      "2" = "White",
      "3" = "Black",
      "4" = "Amer. Indian, AK Native, or mult. races",
      "5" = "Asian, Hawaiian, or Pacific Islander",
      "9" = "White and other"))
