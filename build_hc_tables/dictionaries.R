# Initialize lists ------------------------------------------------------------

statList <- byVars <-
  colGrps <- rowGrps <- rowGrps_R <- colGrps_R <- list()

# Shared groups for HC tables -------------------------------------------------

demo_grps <- list(
  "(none)"             = "ind",
  "Demographics" = c(
    "Age groups"         = "agegrps",
    "Census region"      = "region",
    "Marital status"     = "married",
    "Race/ethnicity"     = "race",
    "Sex"                = "sex"
  ),
  "Socio-economic status" = c(
    "Education"          = "education",
    "Employment status"  = "employed",
    "Insurance coverage" = "insurance",
    "Poverty status"     = "poverty"
  ),
  "Health variables" = c(
    "Perceived health status" = "health",
    "Perceived mental health" = "mnhlth"
  )
)

extension <- list(
  "Event characteristics" = c(
    "Event type"  = "event",
    "Source of payment"  = "sop"))

extended_grps <- append(demo_grps,extension,after=1)


# Use, expenditures, and population characteristics ---------------------------

statList[['hc_use']] = list(
  "Population" = c(
    "Number of people" = "totPOP",
    "Percent of population with an expense (%)" = "pctEXP"
  ),
  "Expenditures" = c(
    "Total expenditures ($)"                        = "totEXP",
    "Mean expenditure per person ($)"               = "meanEXP0",
    "Mean expenditure per person with expense ($)"  = "meanEXP",
    "Median expenditure per person with expense ($)"= "medEXP"
  ),
  "Utilization" = c(
    "Total number of events" = "totEVT",
    "Mean events per person" = "avgEVT",
    "Mean expenditure per event ($)" = "meanEVT"
  )
)

byVars[['hc_use']] <- c('row', 'col')
rowGrps[['hc_use']] <- extended_grps
colGrps[['hc_use']] <- extended_grps

rowGrps_R[['hc_use']] <- rowGrps[['hc_use']] %>% unlist(use.names = F) %>% add_v2X %>% append('event_v2X')
colGrps_R[['hc_use']] <- colGrps[['hc_use']] %>% unlist(use.names = F) %>% add_v2X %>% append('event_v2X')


# Health Insurance ------------------------------------------------------------

statList[['hc_ins']] = list(
  "Number of people" = "totPOP",
  "Percentage of people" = "pctPOP"
)

ins_grps <- demo_grps
ins_grps$`Socio-economic status` = ins_grps$`Socio-economic status` %>% pop("insurance")
ins_grps$Demographics <- append(ins_grps$Demographics, c("Race by Sex" = "racesex"))


byVars[['hc_ins']] <- 'row'
rowGrps[['hc_ins']] <- ins_grps
colGrps[['hc_ins']] <- c("Insurance coverage, all ages" = "insurance",
                      "Insurance coverage, < 65" = "ins_lt65",
                      "Insurance coverage, 65+"  = "ins_ge65")

rowGrps_R[['hc_ins']] <- rowGrps[['hc_ins']] %>% unlist(use.names=F) %>% add_v3X
colGrps_R[['hc_ins']] <- colGrps[['hc_ins']] %>% unlist(use.names=F)


# Accessibility and quality of care -------------------------------------------

byVars[['hc_care']] <- 'row'
rowGrps[['hc_care']] = demo_grps
colGrps[['hc_care']] = list(

  "Access to Care" = c(
    "Usual source of care"  = "usc",
    "Difficulty receiving needed care" = "difficulty",
    "Reasons for difficulty receiving needed care" = "rsn_ANY",
    "Reasons for difficulty receiving needed medical care" = "rsn_MD",
    "Reasons for difficulty receiving needed dental care" = "rsn_DN",
    "Reasons for difficulty receiving needed prescription medicines" = "rsn_PM"
  ),

  "Preventive Care" = c(
    "Adults advised to quit smoking" = "adult_nosmok",
    "Children receiving dental care" = "child_dental"
  ),

  "Diabetes Care" = c(
    "Hemoglobin A1c measurement" = "diab_a1c",
    "Lipid profile" = "diab_chol",
    "Eye exam"  = "diab_eye",
    "Foot care" = "diab_foot",
    "Flu shot" = "diab_flu"
  ),

  "Quality of Care: Adults" = c(
    "Ability to schedule a routine appointment" = "adult_routine",
    "Ability to schedule an appointment for illness or injury" = "adult_illness",
    "How often doctor listened carefully" = "adult_listen",
    "How often doctor explained things"   = "adult_explain",
    "How often doctor showed respect"     = "adult_respect",
    "How often doctor spent enough time"  = "adult_time",
    "Rating for care" = "adult_rating"
  ),

  "Quality of Care: Children" = c(
    "Ability to schedule a routine appointment (child)" = "child_routine",
    "Ability to schedule an appointment for illness or injury (child)" = "child_illness",
    "How often doctor listened carefully (child)" = "child_listen",
    "How often doctor explained things (child)"   = "child_explain",
    "How often doctor showed respect (child)"     = "child_respect",
    "How often doctor spent enough time (child)"  = "child_time",
    "Rating for care (child)" = "child_rating"
  )
)

rowGrps_R[['hc_care']] <- rowGrps[['hc_care']] %>% unlist(use.names=F) %>% add_v2X
colGrps_R[['hc_care']] <- colGrps[['hc_care']] %>% unlist(use.names = F)


careCaption <- list(
  "usc" = "Usual source of care",
  "difficulty" = "Difficulty receiving needed care",
  "rsn_ANY" = "Reasons for difficulty among persons with difficulty receiving needed care",
  "rsn_MD" = "Reasons for difficulty among persons with difficulty receiving needed medical care",
  "rsn_DN" = "Reasons for difficulty among persons with difficulty receiving needed dental care",
  "rsn_PM" = "Reasons for difficulty among persons with difficulty receiving needed prescription medicines",

  "adult_nosmok" = "Adults advised to quit smoking",
  "child_dental" = "Children ages 2-17 receiving dental care",

  "diab_a1c" = "Hemoglobin A1c measurement among adults with diabetes",
  "diab_chol" = "Lipid profile among adults with diabetes",
  "diab_eye" = "Eye exam among adults with diabetes",
  "diab_foot" = "Foot care among adults with diabetes",
  "diab_flu" = "Flu shot among adults with diabetes",

  "adult_routine" = "Ability to schedule a routine appointment, among adults",
  "adult_illness" = "Ability to schedule an appointment for illness or injury, among adults",
  "adult_listen" = "How often doctor listened carefully, among adults with a doctor's visit",
  "adult_explain" = "How often doctor explained things, among adults with a doctor's visit",
  "adult_respect" = "How often doctor showed respect, among adults with a doctor's visit",
  "adult_time" = "How often doctor spent enough time, among adults with a doctor's visit",
  "adult_rating" = "Rating for care, among adults with a doctor's visit",

  "child_routine" = "Ability to schedule a routine appointment, among children",
  "child_illness" = "Ability to schedule an appointment for illness or injury, among children",
  "child_listen" = "How often doctor listened carefully, among children with a doctor's visit",
  "child_explain" = "How often doctor explained things, among children with a doctor's visit",
  "child_respect" = "How often doctor showed respect, among children with a doctor's visit",
  "child_time" = "How often doctor spent enough time, among children with a doctor's visit",
  "child_rating" = "Rating for care, among children with a doctor's visit"
) %>% stack %>% setNames(c("caption", "col_var"))


care_freq <- '
      "4" = "Always",
      "3" = "Usually",
      "2" = "Sometimes/Never",
      "1" = "Sometimes/Never",
      "-7" = "Don\'t know/Non-response",
      "-8" = "Don\'t know/Non-response",
      "-9" = "Don\'t know/Non-response",
      "-15" = "Don\'t know/Non-response",
      "-1" = "Inapplicable"'

care_freq_sas <- '
proc format;
  value freq
   4 = "Always"
   3 = "Usually"
   2 = "Sometimes/Never"
   1 = "Sometimes/Never"
  -7 = "Don\'t know/Non-response"
  -8 = "Don\'t know/Non-response"
  -9 = "Don\'t know/Non-response"
  -15 = "Don\'t know/Non-response"
  -1 = "Inapplicable"
  . = "Missing";
run;
'

statList[['hc_care']] <- list(
  "Number of people" = "totPOP",
  "Percentage of people" = "pctPOP")



# Medical Conditions ----------------------------------------------------------

statList[['hc_cond']] <- statList[['hc_cond_icd10']] <- list(
  "Number of people with care" = "totPOP",
  "Number of events"           = "totEVT",
  "Total expenditures ($)"     = "totEXP",
  "Mean expenditure per person with care ($)"= "meanEXP"
)

byVars[['hc_cond']] <- byVars[['hc_cond_icd10']] <- 'col'
colGrps[['hc_cond']] <- colGrps[['hc_cond_icd10']] <- extended_grps
rowGrps[['hc_cond']] <- rowGrps[['hc_cond_icd10']] <- c("Condition" = "Condition")

rowGrps_R[['hc_cond']] <- rowGrps_R[['hc_cond_icd10']] <- rowGrps[['hc_cond']] %>% unlist(use.names = F)
colGrps_R[['hc_cond']] <- colGrps_R[['hc_cond_icd10']] <- colGrps[['hc_cond']] %>% unlist(use.names = F) %>% add_v2X


# Prescribed Medicines --------------------------------------------------------

statList[['hc_pmed']] <- list(
  "Number of people with purchase" = "totPOP",
  "Total purchases"                = "totEVT",
  "Total expenditures ($)"         = "totEXP")

byVars[['hc_pmed']] <- c('row', 'col')
colGrps[['hc_pmed']] <- c("Total" = "ind")
rowGrps[['hc_pmed']] <- c("Therapeutic class" = "TC1name",
                       "Prescribed drug" = "RXDRGNAM")

rowGrps_R[['hc_pmed']] <- rowGrps[['hc_pmed']] %>% unlist(use.names = F)
colGrps_R[['hc_pmed']] <- colGrps[['hc_pmed']] %>% unlist(use.names = F)
