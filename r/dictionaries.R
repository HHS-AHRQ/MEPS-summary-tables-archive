# Shared -----------------------------------------------------------------

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

# Levels for ordering factors -------------------------------------------------
  age_levels <-
    c("Under 18",
        "Under 5",
        "5-17", "5-6", "7-12", "13-17",
      "18-64",
        "18-44", "18", "19-24", "25-29", "30-34", "35-44",
        "45-64", "45-54", "55-64",
      "65+")

  freq_levels <- c(
    "9-10 rating","7-8 rating","0-6 rating",
    "Don't know/Non-response",
    "Not ascertained",
    "Inapplicable",
    "Missing")

  racesex_levels <- c(
    "Male, Hispanic",
    "Male, Black",
    "Male, White",
    "Male, Amer. Indian, AK Native, or mult. races",
    "Male, Asian, Hawaiian, or Pacific Islander",
    "Male, White and other",

    "Female, Hispanic",
    "Female, Black",
    "Female, White",
    "Female, Amer. Indian, AK Native, or mult. races",
    "Female, Asian, Hawaiian, or Pacific Islander",
    "Female, White and other")


# Levels to exclude in checkbox initially -------------------------------------
  subLevels <- c(
    'Physician office visits', 'Non-physician office visits',
    'Physician hosp. visits', 'Non-physician hosp. visits')

  exclude_initial <- c(
    "All persons", "Any event", "Any source",
    "Under 5", "5-17", "5-6", "7-12", "13-17",
    "18-44", "18", "19-24", "25-29", "30-34", "35-44",
    "45-64", "45-54", "55-64",
    "<65, Any private", "<65, Public only", "<65, Uninsured",
    "65+, Medicare only", "65+, Medicare and private", "65+, Medicare and other public",
    "65+, No medicare"
  ) %>% append(subLevels)



# Event and SOP keys / dictionaries -------------------------------------------

evnt_keys <-
  list("DV"="DVT","ER"="ERT","HH"="HHT","IP"="IPT",
       "OB"="OBV","OM"="OMA","OP"="OPT") %>% stack

evnt_use <-
  list("OBT" = "OBV", "OPD" = "OPY", "OPO" = "OPZ", "IPD" = "IPT") %>% stack


event_dictionary <-
  list("TOT"="Any event",
       "DVT"="Dental visits",
       "RX" ="Prescription medicines",
       "OBV"="Office-based events",
       "OBD"="Physician office visits",
       "OBO"="Non-physician office visits",
       "OPT"="Outpatient events",
       "OPY"="Physician hosp. visits",
       "OPZ"="Non-physician hosp. visits",
       "ERT"="Emergency room visits",
       "IPT"="Inpatient stays",
       "HHT"="Home health events",
       "OMA"="Other medical equipment and services") %>% stack

#
# sop_keys <-
#   list("XP"="EXP","SF"="SLF","PR"="PTR",
#        "MR"="MCR","MD"="MCD","OZ"="OTZ") %>% stack

sp_keys <-
  list("XP" = "EXP", "SF" = "SLF", "PR" = "PTR",
       "MR" = "MCR", "MD" = "MCD", "OZ" = "OTZ") %>% stack

sop_dictionary <-
  list("EXP"="Any source",
       "SLF"="Out of pocket",
       "PTR"="Private",
       "MCR"="Medicare",
       "MCD"="Medicaid",
       "OTZ"="Other") %>% stack

sop_levels <- sop_dictionary$values


delay_dictionary = list(
  "delay_ANY" = "Any care",
  "delay_MD" = "Medical care",
  "delay_DN" = "Dental care",
  "delay_PM" = "Prescription medicines") %>% stack


# App-specific info, stats, and grps ------------------------------------------

infoList  <- statList <- byVars <-
  colGrps <- rowGrps <- rowGrps_R <- colGrps_R <- list()

# Use, expenditures, and population characteristics ---------------------------

infoList[['use']] <- list( title = "Use, expenditures, and population",

img = list(src="../src/custom/img/icon_use.png", alt = "dollars"),

preview = "Utilization, spending, and population totals by demographic characteristics, event type, or source of payment.",

description = "These MEPS summary tables provide statistics on health care utilization and expenditures. Types of data available include number of people, percentage of people with an expense, total expenditures, mean and median expenditures per person, total number of health care events, mean number of events per person, and mean spending per event. Data can be grouped by event type (such as prescription medicines or dental visits), by source of payment (such as Medicare or Medicaid), or by demographic characteristics (such as age, race, or sex).",

instructions1 = '
Use the options below to select a statistic of interest, the data view ("Trends over time" or "Cross-sectional"), data years, and grouping variables. If you select "Trends over time", you can choose a range of years. The "Cross-sectional" view displays a single year, which can be stratified by up to two grouping variables. Once a grouping variable is selected, a dropdown menu will appear, enabling selection of specific levels in each group.',

instructions2 = '
After you select the available options, the table will automatically be updated. The data can be viewed as a plot under the "Plot" tab, with line graphs for trends over time and grouped bar graphs for the cross-sectional view. The "Code" tab displays R and SAS code needed to replicate the data shown in the table. The generated table, plot, and codes can be downloaded with the download button <img height = "25px" src = "../src/custom/img/download-white.png"> under each tab. To view standard errors in the table or 95% confidence intervals in the plot, select the "Show standard errors" checkbox.'
)

statList[['use']] = list(
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

byVars[['use']] <- 'rc'
rowGrps[['use']] <- extended_grps
colGrps[['use']] <- extended_grps

rowGrps_R[['use']] <- rowGrps[['use']] %>% unlist(use.names = F) %>% add_v2X %>% append('event_v2X')
colGrps_R[['use']] <- colGrps[['use']] %>% unlist(use.names = F) %>% add_v2X %>% append('event_v2X')


# Health Insurance ------------------------------------------------------------

infoList[['ins']] <- list( title = "Health insurance",

img = list(src="../src/custom/img/icon_ins.png", alt = "healthcare clipboard"),


preview = "Number and percentage of people by insurance coverage and demographic characteristics.",

description = "These MEPS summary tables provide statistics on health insurance coverage for all ages, persons under 65, and those 65 and older. Data can be viewed over time or for a single year by demographic characteristics (such as age, race, or sex).",

instructions1 = 'Use the options below to select a statistic (number or percentage of people), variable of interest (insurance coverage category), data view ("Trends over time" or "Cross-sectional"), and data years. If you select "Trends over time", you can choose a range of years. The "Cross-sectional" view displays a single year, which can be stratified by a grouping variable. Once a grouping variable is selected, a dropdown will appear, enabling selection of specific levels in each group.',

instructions2 = 'After you select the available options, the table will automatically be updated. The data can be viewed as a plot under the "Plot" tab, with line graphs for trends over time and grouped bar graphs for the cross-sectional view. The "Code" tab displays R and SAS code needed to replicate the data shown in the table. The generated table, plot, and codes can be downloaded with the download button <img height = "25px" src = "../src/custom/img/download-white.png"> under each tab. To view standard errors in the table or 95% confidence intervals in the plot, select the "Show standard errors" checkbox.'
)

statList[['ins']] = list(
  "Number of people" = "totPOP",
  "Percentage of people" = "pctPOP"
)

ins_grps <- demo_grps
ins_grps$`Socio-economic status` = ins_grps$`Socio-economic status` %>% pop("insurance")
ins_grps$Demographics <- append(ins_grps$Demographics, c("Race by Sex" = "racesex"))


byVars[['ins']] <- 'row'
rowGrps[['ins']] <- ins_grps
colGrps[['ins']] <- c("Insurance coverage, all ages" = "insurance",
                      "Insurance coverage, < 65" = "ins_lt65",
                      "Insurance coverage, 65+"  = "ins_ge65")

rowGrps_R[['ins']] <- rowGrps[['ins']] %>% unlist(use.names=F) %>% add_v3X
colGrps_R[['ins']] <- colGrps[['ins']] %>% unlist(use.names=F)


# Accessibility and quality of care -------------------------------------------

infoList[['care']] <- list( title = "Accessibility and quality of care",

img = list(src="../src/custom/img/icon_care.png", alt = "ambulance"),

preview = "Number and percentage of people with a usual source of care, difficulty accessing needed care, preventive care, diabetes care, and patient-reported quality of doctor's visits, by demographic characteristics.",

description = "These MEPS summary tables provide statistics on accessibility and quality of care, such as percentage of the population with a usual source of care, persons with difficulty accessing needed care, persons with diabetes care, and patient-reported quality of doctor's visits. Data can be viewed over time or for a single year by demographic characteristics (such as age, race, or sex).",

instructions1 = '
Use the options below to select a statistic (number or percentage of people), variable of interest, data view ("Trends over time" or "Cross-sectional"), and data years. If you select "Trends over time", you can choose a range of years. The "Cross-sectional" view displays a single year, which can be stratified by a grouping variable. Once a grouping variable is selected, a dropdown will appear, enabling selection of specific levels in each group.',

instructions2 = 'After you select the available options, the table will automatically be updated. The data can be viewed as a plot under the "Plot" tab, with line graphs for trends over time and grouped bar graphs for the cross-sectional view. The "Code" tab displays R and SAS code needed to replicate the data shown in the table. The generated table, plot, and codes can be downloaded with the download button <img height = "25px" src = "../src/custom/img/download-white.png"> under each tab. To view standard errors in the table or 95% confidence intervals in the plot, select the "Show standard errors" checkbox.'
)

byVars[['care']] <- 'row'
rowGrps[['care']] = demo_grps
colGrps[['care']] = list(

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
    "Ability to schedule a routine appointment" = "child_routine",
    "Ability to schedule an appointment for illness or injury" = "child_illness",
    "How often doctor listened carefully" = "child_listen",
    "How often doctor explained things"   = "child_explain",
    "How often doctor showed respect"     = "child_respect",
    "How often doctor spent enough time"  = "child_time",
    "Rating for care" = "child_rating"
  )
)

rowGrps_R[['care']] <- rowGrps[['care']] %>% unlist(use.names=F) %>% add_v2X
colGrps_R[['care']] <- colGrps[['care']] %>% unlist(use.names = F)


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
)


care_freq <- '
      "4" = "Always",
      "3" = "Usually",
      "2" = "Sometimes/Never",
      "1" = "Sometimes/Never",
      "-7" = "Don\'t know/Non-response",
      "-8" = "Don\'t know/Non-response",
      "-9" = "Don\'t know/Non-response",
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
  -1 = "Inapplicable"
  . = "Missing";
run;
'

statList[['care']] <- list(
  "Number of people" = "totPOP",
  "Percentage of people" = "pctPOP")



# Medical Conditions ----------------------------------------------------------

infoList[['cond']] <- list( title = "Medical conditions",

img = list(src="../src/custom/img/icon_cond.png", alt = "pulse"),

preview = "Utilization, spending, and number of people with care for medical conditions by demographic characteristics.",

description = "These MEPS summary tables provide statistics on the number of people with care for medical conditions, health care utilization, total expenditures, and mean expenditures per person by medical condition. Data can be viewed over time or for a single year by event type (such as prescription medicines or outpatient events), source of payment (such as Medicare or Medicaid), or demographic characteristics (such as age, race, or sex).",

instructions1 = 'Use the options below to select a statistic of interest, data view ("Trends over time" or "Cross-sectional"), and data years. If you select "Trends over time", you can choose a range of years. The "Cross-sectional" view displays a single year, which can be stratified by a grouping variable. Once a grouping variable is selected, a dropdown will appear, enabling selection of specific levels in each group.',

instructions2 = 'After you select the available options, the table will automatically be updated. The table can be sorted by condition name or data value by clicking on the column header. To view the data as a plot, with line graphs for trends over time and grouped bar graphs for the cross-sectional view, select up to 10 rows by clicking in the table. The "Code" tab displays R and SAS code needed to replicate the data shown in the table. The generated table, plot, and codes can be downloaded with the download button <img height = "25px" src = "../src/custom/img/download-white.png"> under each tab. To view standard errors in the table or 95% confidence intervals in the plot, select the "Show standard errors" checkbox.'
)

statList[['cond']] = list(
  "Number of people with care" = "totPOP",
  "Number of events"           = "totEVT",
  "Total expenditures ($)"     = "totEXP",
  "Mean expenditure per person with care ($)"= "meanEXP"
)

byVars[['cond']] <- 'col'
colGrps[['cond']] <- extended_grps
rowGrps[['cond']] <- "Condition"

rowGrps_R[['cond']] <- rowGrps[['cond']] %>% unlist(use.names = F)
colGrps_R[['cond']] <- colGrps[['cond']] %>% unlist(use.names = F) %>% add_v2X


# Prescribed Medicines --------------------------------------------------------

infoList[['pmed']] <- list( title = "Prescribed drugs",

img = list(src="../src/custom/img/icon_pmed.png", alt = "pills"),

preview = "Purchases and spending by prescribed drug or therapeutic class.",

description = "These MEPS summary tables provide statistics on total expenditures, total purchases, and number of persons with purchases for prescription medicines or therapeutic class groups. Tables are available for the years 2013-2015. Tables from earlier years will be available shortly.",

instructions1 = 'Use the options below to select a statistic of interest, data years, and grouping variable (therapeutic class or generic drug name). After you select the available options, the table will automatically be updated. The table can be sorted by drug name or therapeutic class name, or data values for each year by clicking on the column header.',

instructions2 = 'To view data as a plot, select up to 10 rows by clicking in the table. The "Code" tab displays R and SAS code needed to replicate the data shown in the table. The generated table, plot, and codes can be downloaded with the download button <img height = "25px" src = "../src/custom/img/download-white.png"> under each tab. To view standard errors in the table or 95% confidence intervals in the plot, select the "Show standard errors" checkbox.'
)


statList[['pmed']] <- list(
  "Number of people with purchase" = "totPOP",
  "Total purchases"                = "totEVT",
  "Total expenditures ($)"         = "totEXP")

byVars[['pmed']] <- 'rc'
colGrps[['pmed']] <- c("ind")
rowGrps[['pmed']] <- c("Therapeutic class" = "TC1name",
                       "Prescribed drug" = "RXDRGNAM")

rowGrps_R[['pmed']] <- rowGrps[['pmed']] %>% unlist(use.names = F)
colGrps_R[['pmed']] <- colGrps[['pmed']] %>% unlist(use.names = F)
