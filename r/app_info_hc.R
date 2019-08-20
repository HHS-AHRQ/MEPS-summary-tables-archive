
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
    'Office-based physician visits',
    'Outpatient physician visits')

  exclude_initial <- c(
    "All persons", "Any event", "Any source",
    "Under 5", "5-17", "5-6", "7-12", "13-17",
    "18-44", "18", "19-24", "25-29", "30-34", "35-44",
    "45-64", "45-54", "55-64",
    "<65, Any private", "<65, Public only", "<65, Uninsured",
    "65+, Medicare only", "65+, Medicare and private", "65+, Medicare and other public",
    "65+, No medicare"
  ) %>% append(subLevels)




## Info list for all apps -----------------------------------------------------

infoList <- list()

## HOME PAGE ------------------------------------------------------------------

infoList[['home']] <- list(

description =
'The MEPS Household Component summary tables provide frequently used summary estimates for the U.S. civilian noninstitutionalized population on household medical utilization and expenditures, demographic and socio-economic characteristics, health insurance coverage, access to care and experience with care, medical conditions, and prescribed medicine purchases. Most tables can be stratified by demographic or socio-economic characteristics. Plots from selected data can also be generated, and R and SAS code for calculating selected estimates is available. See <a href="https://meps.ahrq.gov/mepsweb/survey_comp/hc_data_collection.jsp">Sample Design and Data Collection Process</a> for details on the collection of individual data items (e.g., health insurance status, age). The estimates provided in the tables are based on data available in standardized <a href="https://meps.ahrq.gov/mepsweb/data_stats/download_data_files.jsp">public use data files.</a> Pages have been optimized for Chrome, Firefox, and Safari.'

)



## HOUSEHOLD COMPONENT --------------------------------------------------------

# Use, expenditures, and population characteristics -----------------

infoList[['hc_use']] <- list(

title = "Use, expenditures, and population",

img = list(src="../src/custom/img/icon_use.png", alt = "dollars"),

preview = "Utilization, spending, and population totals by demographic characteristics, event type, or source of payment.",

description = "These MEPS summary tables provide statistics on health care utilization and expenditures. Types of data available include number of people, percentage of people with an expense, total expenditures, mean and median expenditures per person, total number of health care events, mean number of events per person, and mean spending per event. Data can be grouped by event type (such as prescription medicines or dental visits), by source of payment (such as Medicare or Medicaid), or by demographic characteristics (such as age, race, or sex).",

instructions1 = '
Use the options below to select a statistic of interest, the data view ("Trends over time" or "Cross-sectional"), data years, and grouping variables. If you select "Trends over time", you can choose a range of years. The "Cross-sectional" view displays a single year, which can be stratified by up to two grouping variables. Once a grouping variable is selected, a dropdown menu will appear, enabling selection of specific levels in each group.',

instructions2 = '
After you select the available options, the table will automatically be updated. The data can be viewed as a plot under the "Plot" tab, with line graphs for trends over time and grouped bar graphs for the cross-sectional view. The "Code" tab displays R and SAS code needed to replicate the data shown in the table. The generated table, plot, and codes can be downloaded with the download button <img height = "25px" src = "../src/custom/img/download-white.png"> under each tab. To view standard errors in the table or 95% confidence intervals in the plot, select the "Show standard errors" checkbox.'
)


# Health Insurance --------------------------------------------------

infoList[['hc_ins']] <- list(

title = "Health insurance",

img = list(src="../src/custom/img/icon_ins.png", alt = "healthcare clipboard"),


preview = "Number and percentage of people by insurance coverage and demographic characteristics.",

description = "These MEPS summary tables provide statistics on health insurance coverage for all ages, persons under 65, and those 65 and older. Data can be viewed over time or for a single year by demographic characteristics (such as age, race, or sex).",

instructions1 = 'Use the options below to select a statistic (number or percentage of people), variable of interest (insurance coverage category), data view ("Trends over time" or "Cross-sectional"), and data years. If you select "Trends over time", you can choose a range of years. The "Cross-sectional" view displays a single year, which can be stratified by a grouping variable. Once a grouping variable is selected, a dropdown will appear, enabling selection of specific levels in each group.',

instructions2 = 'After you select the available options, the table will automatically be updated. The data can be viewed as a plot under the "Plot" tab, with line graphs for trends over time and grouped bar graphs for the cross-sectional view. The "Code" tab displays R and SAS code needed to replicate the data shown in the table. The generated table, plot, and codes can be downloaded with the download button <img height = "25px" src = "../src/custom/img/download-white.png"> under each tab. To view standard errors in the table or 95% confidence intervals in the plot, select the "Show standard errors" checkbox.'
)


# Accessibility and quality of care ---------------------------------

infoList[['hc_care']] <- list(

title = "Accessibility and quality of care",

img = list(src="../src/custom/img/icon_care.png", alt = "ambulance"),

preview = "Number and percentage of people with a usual source of care, difficulty accessing needed care, preventive care, diabetes care, and patient-reported quality of doctor's visits, by demographic characteristics.",

description = "These MEPS summary tables provide statistics on accessibility and quality of care, such as percentage of the population with a usual source of care, persons with difficulty accessing needed care, persons with diabetes care, and patient-reported quality of doctor's visits. Data can be viewed over time or for a single year by demographic characteristics (such as age, race, or sex).",

instructions1 = '
Use the options below to select a statistic (number or percentage of people), variable of interest, data view ("Trends over time" or "Cross-sectional"), and data years. If you select "Trends over time", you can choose a range of years. The "Cross-sectional" view displays a single year, which can be stratified by a grouping variable. Once a grouping variable is selected, a dropdown will appear, enabling selection of specific levels in each group.',

instructions2 = 'After you select the available options, the table will automatically be updated. The data can be viewed as a plot under the "Plot" tab, with line graphs for trends over time and grouped bar graphs for the cross-sectional view. The "Code" tab displays R and SAS code needed to replicate the data shown in the table. The generated table, plot, and codes can be downloaded with the download button <img height = "25px" src = "../src/custom/img/download-white.png"> under each tab. To view standard errors in the table or 95% confidence intervals in the plot, select the "Show standard errors" checkbox.'
)


# Medical Conditions ------------------------------------------------

infoList[['hc_cond']] <- list(

title = "Medical conditions",

img = list(src="../src/custom/img/icon_cond.png", alt = "pulse"),

preview = "Utilization, spending, and number of people with care for medical conditions by demographic characteristics.",

description = "These MEPS summary tables provide statistics on the number of people with care for medical conditions, health care utilization, total expenditures, and mean expenditures per person by medical condition. Data can be viewed over time or for a single year by event type (such as prescription medicines or outpatient events), source of payment (such as Medicare or Medicaid), or demographic characteristics (such as age, race, or sex).",

instructions1 = 'Use the options below to select a statistic of interest, data view ("Trends over time" or "Cross-sectional"), and data years. If you select "Trends over time", you can choose a range of years. The "Cross-sectional" view displays a single year, which can be stratified by a grouping variable. Once a grouping variable is selected, a dropdown will appear, enabling selection of specific levels in each group.',

instructions2 = 'After you select the available options, the table will automatically be updated. The table can be sorted by condition name or data value by clicking on the column header. To view the data as a plot, with line graphs for trends over time and grouped bar graphs for the cross-sectional view, select up to 10 rows by clicking in the table. The "Code" tab displays R and SAS code needed to replicate the data shown in the table. The generated table, plot, and codes can be downloaded with the download button <img height = "25px" src = "../src/custom/img/download-white.png"> under each tab. To view standard errors in the table or 95% confidence intervals in the plot, select the "Show standard errors" checkbox.'
)


# Prescribed Medicines ----------------------------------------------

infoList[['hc_pmed']] <- list(

title = "Prescribed drugs",

img = list(src="../src/custom/img/icon_pmed.png", alt = "pills"),

preview = "Purchases and spending by prescribed drug or therapeutic class.",

description = "These MEPS summary tables provide statistics on total expenditures, total purchases, and number of persons with purchases for prescription medicines or therapeutic class groups.",

instructions1 = 'Use the options below to select a statistic of interest, data years, and grouping variable (therapeutic class or generic drug name). After you select the available options, the table will automatically be updated. The table can be sorted by drug name or therapeutic class name, or data values for each year by clicking on the column header.',

instructions2 = 'To view data as a plot, select up to 10 rows by clicking in the table. The "Code" tab displays R and SAS code needed to replicate the data shown in the table. The generated table, plot, and codes can be downloaded with the download button <img height = "25px" src = "../src/custom/img/download-white.png"> under each tab. To view standard errors in the table or 95% confidence intervals in the plot, select the "Show standard errors" checkbox.'
)
