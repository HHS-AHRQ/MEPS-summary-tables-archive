# Diabetes care: Flu shot
  if(year > 2007){
    FYC <- FYC %>%
      mutate(
        past_year = (DSFL.yy.53==1 | DSFL.ya.53==1),
        more_year = (DSFL.yb.53==1 | DSVB.yb.53==1),
        never_chk = (DSFLNV53 == 1),
        non_resp  = (DSFL.yy.53 %in% c(-7,-8,-9))
      )
  }else{
    FYC <- FYC %>%
      mutate(
        past_year = (FLUSHT53 == 1),
        more_year = (1 < FLUSHT53 & FLUSHT53 < 6),
        never_chk = (FLUSHT53 == 6),
        non_resp  = (FLUSHT53 %in% c(-7,-8,-9))
      )
  }

  FYC <- FYC %>%
    mutate(
      diab_flu = as.factor(case_when(
        .$past_year ~ "In the past year",
        .$more_year ~ "More than 1 year ago",
        .$never_chk ~ "Never had flu shot",
        .$non_resp ~ "Don\'t know/Non-response",
        TRUE ~ "Missing")))
