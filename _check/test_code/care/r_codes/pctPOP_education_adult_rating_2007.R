# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/h113.ssp');
  year <- 2007
  
  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE07X, AGE42X, AGE31X))

  FYC$ind = 1

# Rating for care (adults)
  FYC <- FYC %>%
    mutate(
      adult_rating = as.factor(case_when(
        .$ADHECR42 >= 9 ~ "9-10 rating",
        .$ADHECR42 >= 7 ~ "7-8 rating",
        .$ADHECR42 >= 0 ~ "0-6 rating",
        .$ADHECR42 == -1 ~ "Inapplicable",
        .$ADHECR42 <= -7 ~ "Don\'t know/Non-response",
        TRUE ~ "Missing")))

# Education
  if(year <= 1998){
    FYC <- FYC %>% mutate(EDUCYR = EDUCYR07)
  }else if(year <= 2004){
    FYC <- FYC %>% mutate(EDUCYR = EDUCYEAR)
  }

  if(year >= 2012){
    FYC <- FYC %>%
      mutate(
        less_than_hs = (0 <= EDRECODE & EDRECODE < 13),
        high_school  = (EDRECODE == 13),
        some_college = (EDRECODE > 13))

  }else{
    FYC <- FYC %>%
      mutate(
        less_than_hs = (0 <= EDUCYR & EDUCYR < 12),
        high_school  = (EDUCYR == 12),
        some_college = (EDUCYR > 12))
  }

  FYC <- FYC %>% mutate(
    education = 1*less_than_hs + 2*high_school + 3*some_college,
    education = replace(education, AGELAST < 18, 9),
    education = recode_factor(education, .default = "Missing",
      "1" = "Less than high school",
      "2" = "High school",
      "3" = "Some college",
      "9" = "Inapplicable (age < 18)",
      "0" = "Missing"))

SAQdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~SAQWT07F,
  data = FYC,
  nest = TRUE)

svyby(~adult_rating, FUN=svymean, by = ~education, design = subset(SAQdsgn, ADAPPT42 >= 1 & AGELAST >= 18))
