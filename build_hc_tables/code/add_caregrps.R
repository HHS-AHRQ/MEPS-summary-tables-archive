
# Access to care --------------------------------------------------------------

## Usual source of care

FYC <- FYC %>%
  mutate(usc = ifelse(HAVEUS42 == 2, 0, LOCATN42)) %>%
  mutate(usc = recode_factor(
    usc,
    .default = "Missing",
    .missing = "Missing",
    "0" = "No usual source of health care",
    "1" = "Office-based",
    "2" = "Hospital (not ER)",
    "3" = "Emergency room"))

## Difficulty receiving needed care

MDP <- c("MD", "DN", "PM")

difficulty_vars <- c(
  paste0(MDP, "UNAB42"),
  paste0(MDP, "DLAY42"),
  paste0(MDP, "DLRS42"),
  paste0(MDP, "UNRS42"))


if(all(difficulty_vars %in% colnames(FYC))) {

  ## Reason for difficulty receiving needed care
  FYC <- FYC %>%
    mutate(
      delay_MD  = (MDUNAB42 == 1 | MDDLAY42==1)*1,
      delay_DN  = (DNUNAB42 == 1 | DNDLAY42==1)*1,
      delay_PM  = (PMUNAB42 == 1 | PMDLAY42==1)*1,

      afford_MD = (MDDLRS42 == 1 | MDUNRS42 == 1)*1,
      afford_DN = (DNDLRS42 == 1 | DNUNRS42 == 1)*1,
      afford_PM = (PMDLRS42 == 1 | PMUNRS42 == 1)*1,

      insure_MD = (MDDLRS42 %in% c(2,3) | MDUNRS42 %in% c(2,3))*1,
      insure_DN = (DNDLRS42 %in% c(2,3) | DNUNRS42 %in% c(2,3))*1,
      insure_PM = (PMDLRS42 %in% c(2,3) | PMUNRS42 %in% c(2,3))*1,

      other_MD  = (MDDLRS42 > 3 | MDUNRS42 > 3)*1,
      other_DN  = (DNDLRS42 > 3 | DNUNRS42 > 3)*1,
      other_PM  = (PMDLRS42 > 3 | PMUNRS42 > 3)*1,

      delay_ANY  = (delay_MD  | delay_DN  | delay_PM)*1,
      afford_ANY = (afford_MD | afford_DN | afford_PM)*1,
      insure_ANY = (insure_MD | insure_DN | insure_PM)*1,
      other_ANY  = (other_MD  | other_DN  | other_PM)*1)

}



# Preventive care -------------------------------------------------------------

## Adults advised to quit smoking

if(year == 2002)
  FYC <- FYC %>% rename(ADNSMK42 = ADDSMK42)

if("ADNSMK42" %in% colnames(FYC)) {
  FYC <- FYC %>%
    mutate(
      adult_nosmok = recode_factor(
        ADNSMK42,
        .default = "Missing",
        .missing = "Missing",
        "1" = "Told to quit",
        "2" = "Not told to quit",
        "3" = "Had no visits in the last 12 months",
        "-9" = "Not ascertained",
        "-15" = "Not ascertained",
        "-1" = "Inapplicable"))
}

# Children receiving dental care

FYC <- FYC %>%
  mutate(
    child_2to17 = (1 < AGELAST & AGELAST < 18),
    child_dental = ((DVTOT > 0) & (child_2to17==1))*1,
    child_dental = recode_factor(
      child_dental, .default = "Missing", .missing = "Missing",
      "1" = "One or more dental visits",
      "0" = "No dental visits in past year"))

# Diabetes Care ---------------------------------------------------------------

## Diabetes care: Hemoglobin A1c measurement

FYC <- FYC %>%
  mutate(diab_a1c = ifelse(0 < DSA1C53 & DSA1C53 < 96, 1, DSA1C53)) %>%
  mutate(diab_a1c = replace(diab_a1c,DSA1C53==96,0)) %>%
  mutate(diab_a1c = recode_factor(
    diab_a1c,
    .default = "Missing",
    .missing = "Missing",
    "1" = "Had measurement",
    "0" = "Did not have measurement",
    "-7" = "Don't know/Non-response",
    "-8" = "Don't know/Non-response",
    "-9" = "Don't know/Non-response",
    "-15" = "Don't know/Non-response",
    "-1" = "Inapplicable"))

## Diabetes care: Lipid profile

if(year > 2007){
  FYC <- FYC %>%
    mutate(
      past_year = (DSCH53==1   | DSCHya53==1),
      more_year = (DSCHyb53==1 | DSCByb53==1),
      never_chk = (DSCHNV53 == 1),
      non_resp  = (DSCH53 %in% c(-7,-8,-9,-15))
    )
}else{
  FYC <- FYC %>%
    mutate(
      past_year = (CHOLCK53 == 1),
      more_year = (1 < CHOLCK53 & CHOLCK53 < 6),
      never_chk = (CHOLCK53 == 6),
      non_resp  = (CHOLCK53 %in% c(-7,-8,-9,-15))
    )
}

FYC <- FYC %>%
  mutate(
    diab_chol = as.factor(
      case_when(
        past_year ~ "In the past year",
        more_year ~ "More than 1 year ago",
        never_chk ~ "Never had cholesterol checked",
        non_resp ~ "Don't know/Non-response",
        TRUE ~ "Missing")))

## Diabetes care: Eye exam

FYC <- FYC %>%
  mutate(
    past_year = (DSEY53==1   | DSEYya53==1),
    more_year = (DSEYyb53==1 | DSEByb53==1),
    never_chk = (DSEYNV53 == 1),
    non_resp = (DSEY53 %in% c(-7,-8,-9,-15))
  )

FYC <- FYC %>%
  mutate(
    diab_eye = as.factor(case_when(
      past_year ~ "In the past year",
      more_year ~ "More than 1 year ago",
      never_chk ~ "Never had eye exam",
      non_resp ~ "Don't know/Non-response",
      TRUE ~ "Missing")))

## Diabetes care: Foot care

if(year > 2007){
  FYC <- FYC %>%
    mutate(
      past_year = (DSFT53==1   | DSFTya53==1),
      more_year = (DSFTyb53==1 | DSFByb53==1),
      never_chk = (DSFTNV53 == 1),
      non_resp  = (DSFT53 %in% c(-7,-8,-9,-15)),
      inapp     = (DSFT53 == -1),
      not_past_year = FALSE
    )
}else{
  FYC <- FYC %>%
    mutate(
      past_year = (DSCKFT53 >= 1),
      not_past_year = (DSCKFT53 == 0),
      non_resp  = (DSCKFT53 %in% c(-7,-8,-9,-15)),
      inapp     = (DSCKFT53 == -1),
      more_year = FALSE,
      never_chk = FALSE
    )
}

FYC <- FYC %>%
  mutate(
    diab_foot = as.factor(case_when(
      past_year ~ "In the past year",
      more_year ~ "More than 1 year ago",
      never_chk ~ "Never had feet checked",
      not_past_year ~ "No exam in past year",
      non_resp ~ "Don't know/Non-response",
      inapp ~ "Inapplicable",
      TRUE ~ "Missing")))

## Diabetes care: Flu shot

if(year > 2007){
  FYC <- FYC %>%
    mutate(
      past_year = (DSFL53==1   | DSFLya53==1),
      more_year = (DSFLyb53==1 | DSVByb53==1),
      never_chk = (DSFLNV53 == 1),
      non_resp  = (DSFL53 %in% c(-7,-8,-9,-15))
    )
}else{
  FYC <- FYC %>%
    mutate(
      past_year = (FLUSHT53 == 1),
      more_year = (1 < FLUSHT53 & FLUSHT53 < 6),
      never_chk = (FLUSHT53 == 6),
      non_resp  = (FLUSHT53 %in% c(-7,-8,-9,-15))
    )
}

FYC <- FYC %>%
  mutate(
    diab_flu = as.factor(
      case_when(
        past_year ~ "In the past year",
        more_year ~ "More than 1 year ago",
        never_chk ~ "Never had flu shot",
        non_resp ~ "Don't know/Non-response",
        TRUE ~ "Missing")))

# Quality of care -------------------------------------------------------------
# Only gathered every odd year, starting in 2017

freq_levels <- c(
  "4" = "Always",
  "3" = "Usually",
  "2" = "Sometimes/Never",
  "1" = "Sometimes/Never",
  "-7" = "Don't know/Non-response",
  "-8" = "Don't know/Non-response",
  "-9" = "Don't know/Non-response",
  "-15" = "Don't know/Non-response",
  "-1" = "Inapplicable")

qual_vars_adults <- c(
  "ADRTWW42", "ADILWW42", "ADLIST42", "ADEXPL42",
  "ADRESP42", "ADPRTM42", "ADHECR42")

qual_vars_child <- c(
  "CHRTWW42", "CHILWW42", "CHLIST42", "CHEXPL42",
  "CHRESP42", "CHPRTM42", "CHHECR42")

# ADULTS ------------------------------------------------------------

if(all(qual_vars_adults %in% colnames(FYC))) {

  # Ability to schedule a routine appt. (adults)
  FYC <- FYC %>%
    mutate(adult_routine = recode_factor(
      ADRTWW42, .default = "Missing", .missing = "Missing", !!!freq_levels))

  # Ability to schedule appt. for illness or injury (adults)
  FYC <- FYC %>%
    mutate(adult_illness = recode_factor(
      ADILWW42, .default = "Missing", .missing = "Missing", !!!freq_levels))

  # How often doctor listened carefully (adults)
  FYC <- FYC %>%
    mutate(adult_listen = recode_factor(
      ADLIST42, .default = "Missing", .missing = "Missing", !!!freq_levels))

  # How often doctor explained things (adults)
  FYC <- FYC %>%
    mutate(adult_explain = recode_factor(
      ADEXPL42, .default = "Missing", .missing = "Missing", !!!freq_levels))

  # How often doctor showed respect (adults)
  FYC <- FYC %>%
    mutate(adult_respect = recode_factor(
      ADRESP42, .default = "Missing", .missing = "Missing", !!!freq_levels))

  # How often doctor spent enough time (adults)
  FYC <- FYC %>%
    mutate(adult_time = recode_factor(
      ADPRTM42, .default = "Missing", .missing = "Missing", !!!freq_levels))

  # Rating for care (adults)
  FYC <- FYC %>%
    mutate(
      adult_rating = as.factor(
        case_when(
          .$ADHECR42 >= 9 ~ "9-10 rating",
          .$ADHECR42 >= 7 ~ "7-8 rating",
          .$ADHECR42 >= 0 ~ "0-6 rating",
          .$ADHECR42 == -1 ~ "Inapplicable",
          .$ADHECR42 <= -7 ~ "Don\'t know/Non-response",
          TRUE ~ "Missing")))
}

# CHILDREN ----------------------------------------------------------

if(all(qual_vars_child %in% colnames(FYC))) {

  # Ability to schedule a routine appt. (children)
  FYC <- FYC %>%
    mutate(child_routine = recode_factor(
      CHRTWW42, .default = "Missing", .missing = "Missing", !!!freq_levels))

  # Ability to schedule appt. for illness or injury (children)
  FYC <- FYC %>%
    mutate(child_illness = recode_factor(
      CHILWW42, .default = "Missing", .missing = "Missing", !!!freq_levels))

  # How often doctor listened carefully (children)
  FYC <- FYC %>%
    mutate(child_listen = recode_factor(
      CHLIST42, .default = "Missing", .missing = "Missing", !!!freq_levels))

  # How often doctor explained things (children)
  FYC <- FYC %>%
    mutate(child_explain = recode_factor(
      CHEXPL42, .default = "Missing", .missing = "Missing", !!!freq_levels))

  # How often doctor showed respect (children)
  FYC <- FYC %>%
    mutate(child_respect = recode_factor(
      CHRESP42, .default = "Missing", .missing = "Missing", !!!freq_levels))

  # How often doctor spent enough time (children)
  FYC <- FYC %>%
    mutate(child_time = recode_factor(
      CHPRTM42, .default = "Missing", .missing = "Missing", !!!freq_levels))

  # Rating for care (children)
  FYC <- FYC %>%
    mutate(
      child_rating = as.factor(
        case_when(
          .$CHHECR42 >= 9 ~ "9-10 rating",
          .$CHHECR42 >= 7 ~ "7-8 rating",
          .$CHHECR42 >= 0 ~ "0-6 rating",
          .$CHHECR42 == -1 ~ "Inapplicable",
          .$CHHECR42 <= -7 ~ "Don\'t know/Non-response",
          TRUE ~ "Missing")))
}
