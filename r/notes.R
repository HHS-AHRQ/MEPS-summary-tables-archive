controlTotals_message <- "(Standard errors are approximately zero for control totals)"

suppressed_message <- " -- Estimates suppressed due to inadequate precision (see <a  target='_blank_'
href = 'https://meps.ahrq.gov/survey_comp/precision_guidelines.shtml'>
FAQs</a> for details).<br>"

rse_message <- " * Relative standard error is greater than 30%.<br>"

notes <- list()

# Statistics -----------------------------------------------------------

notes$care <- notes$ins <- notes$use <- notes$cond <- notes$pmed <- list()

notes$care$pctPOP <- notes$ins$pctPOP <- "
Percentages may not sum to 100 due to rounding.
"

notes$use$totEVT <- notes$use$meanEVT <- notes$use$avgEVT <- "
<h4>Utilization</h4>
Events include all dental visits, prescribed medicine purchases, office-based and outpatient visits, emergency room visits, inpatient stays, and home health events. A <i>home health event</i> is defined as one month during which home health service was received. <i>Other medical equipment and services</i> are not included in utilization estimates because information for these events is collected per interview (e.g. eyeglasses) or per year (e.g. wheelchairs, hearing aids) for each person, rather than on a per-purchase basis.
"

notes$cond$totEVT <- "
<h4>Utilization</h4>
Events include all emergency room visits, home health events, inpatient stays, office-based and outpatient visits, and prescribed medicine purchases associated with a medical condition. A <i>home health event</i> is defined as one month during which home health service was received.
"



notes$use$totEXP <- notes$use$meanEXP <- notes$use$meanEXP0 <- notes$use$medEXP <-
  notes$cond$totEXP <- notes$cond$meanEXP <- "
<h4>Expenditures</h4>
Expenditures include payments for medical events reported during the calendar year. Expenditures in MEPS are defined as the sum of direct payments for care provided during the year, including out-of-pocket payments and payments by private insurance, Medicaid, Medicare, and other sources. Payments for over-the-counter drugs and phone contacts with medical providers are not included in MEPS total expenditure estimates. Indirect payments not related to specific medical events, such as Medicaid Disproportionate Share and Medicare Direct Medical Education subsidies, also are not included. Any charges associated with uncollected liability, bad debt, and charitable care (unless provided by a public clinic or hospital) are not counted as expenditures.
"

notes$use$medEXP <- paste(notes$use$medEXP, "<p>
The median and standard error estimates in this table were produced by the R Programming Language (version 3.3.3). Median and corresponding standard errors produced by different programming languages may differ slightly, due to varying methods for calculating medians and standard errors for survey data.
</p>
")


# Demographics  --------------------------------------------------------

notes$agegrps <- "
<h4>Age groups</h4>
Respondents were asked to report the age of each family member as of the date of each interview for each round of data collection. The age variable used to create these estimates is based on the sample person's age as of the end of the year. If data were not collected during a round because the sample person was out of scope (e.g., deceased or institutionalized), then age at the time of the previous round was used.
"

notes$region <- "
<h4>Region</h4>
The census region variable is based on the location of the household at the end of the year. If missing, the most recent location available is used.
<ul>
  <li><i>Northeast:</i> Maine, New Hampshire, Vermont, Massachusetts, Rhode Island, Connecticut, New York, New Jersey, and Pennsylvania.</li>

  <li><i>Midwest:</i> Ohio, Indiana, Illinois, Michigan, Wisconsin, Minnesota, Iowa, Missouri, North Dakota, South Dakota, Nebraska, and Kansas.</li>

  <li><i>South:</i></i> Delaware, Maryland, District of Columbia, Virginia, West Virginia, North Carolina, South Carolina, Georgia, Florida, Kentucky, Tennessee, Alabama, Mississippi, Arkansas, Louisiana, Oklahoma, and Texas.</li>

  <li><i>West:</i> Montana, Idaho, Wyoming, Colorado, New Mexico, Arizona, Utah, Nevada, Washington, Oregon, California, Alaska, and Hawaii.</li>
</ul>
"

notes$health <- "
<h4>Perceived health status</h4>
<p>The MEPS respondent was asked to rate the health of each person in the family at the time of the interview according to the following categories: excellent, very good, good, fair, and poor. For persons with missing health status in a round, the response for health status at the previous round was used, if available. A small percentage of persons (< 2 percent) had a missing response for <i>perceived health status</i>.</p>
"

notes$mnhlth <- "
<h4>Perceived mental health</h4>
<p>The MEPS respondent was asked to rate the mental health of each person in the family at the time of the interview according to the following categories: excellent, very good, good, fair, and poor. For persons with missing mental health status in a round, the response for mental health status at the previous round was used, if available. A small percentage of persons (< 2 percent) had a missing response for <i>perceived mental health status</i>.</p>
"

notes$married <- "
<h4>Marital status</h4>
Marital status is based on the person's marital status at the end of the year. If missing, the most recent non-missing marital status variable is used. A small percentage of persons (< 2 percent) had a missing value for <i>marital status</i>.
"

notes$education <- "
<h4>Education</h4>
Education for each person is based on the highest education level completed when entering MEPS. A small percentage of persons (< 2 percent) had a missing response for <i>education</i>.
"

notes$employed <- "
<h4>Employment status</h4>
Employment status is based on the person's employment status at the end of the year. If missing, the most recent non-missing employment status variable is used. A small percentage of persons (< 2 percent) had a missing response for <i>employment status</i>.
"

notes$insurance <- notes$ins_lt65 <- notes$ins_ge65 <- "
<h4>Insurance coverage</h4>
<ul>
<li><i>Uninsured:</i>
Individuals who did not have health insurance coverage for the entire calendar year were classified as uninsured. The uninsured were defined as people not covered by Medicaid, Medicare, TRICARE (Armed Forces-related coverage), other public hospital/physician programs, private hospital/physician insurance (including Medigap coverage) or insurance purchased through health insurance Marketplaces. People covered only by non-comprehensive State-specific programs (e.g., Maryland Kidney Disease Program) or private single service plans such as coverage for dental or vision care only, or coverage for accidents or specific diseases, were considered uninsured.
</li>

<li><i>Any private:</i>
Individuals classified as having any private health insurance coverage had private insurance that provided coverage for hospital and physician care (including Medigap coverage and TRICARE) at some point during the year.</li>

<li><i>Public only:</i>
Individuals are considered to have public only health insurance coverage if they were not covered by private insurance or TRICARE and they were covered by Medicare, Medicaid, or other public hospital and physician coverage at some point during the year.</li>

<li><i>65+, No Medicare:</i>
Individuals classified as <i>65+, No Medicare</i> either had private coverage at some point during the year that is not identified as Medigap coverage or were uninsured throughout the year.</li>
</ul>
"

notes$sop <- "
<h4>Source of payment</h4>
<ul>
<li><i>Private:</i> Includes payments made by insurance plans covering hospital and medical care (excluding payments from Medicare, Medicaid, and other public sources). Payments from Medigap plans or TRICARE (Armed-Forces-related coverage) are included.</li>

<li><i>Medicare:</i> A federally financed health insurance plan for the elderly, persons receiving Social Security disability payments, and most persons with end-stage renal disease. Medicare Part A, which provides hospital insurance, is automatically given to those who are eligible for Social Security. Medicare Part B provides supplementary medical insurance that pays for medical expenses and can be purchased for a monthly premium.
</li>

<li><i>Medicaid:</i> A means-tested government program jointly financed by federal and state funds that provides health care to those who are eligible. Program eligibility criteria vary significantly by state, but the program is designed to provide health coverage to families and individuals who are unable to afford necessary medical care.
</li>

<li><i>Other:</i> Includes payments from the Department of Veterans Affairs (excluding TRICARE); other federal sources (Indian Health Service, military treatment facilities, and other care provided by the Federal Government); various state and local sources (community and neighborhood clinics, State and local health departments, and State programs other than Medicaid); payments from Workers' Compensation; and, other unclassified sources (e.g., automobile, homeowner's, or liability insurance, and other miscellaneous or unknown sources). It also includes private insurance payments reported for persons without private health insurance coverage during the year, as defined in MEPS, and Medicaid payments reported for persons who were not enrolled in the Medicaid program at any time during the year.
</li>
</ul>
"

notes$poverty <- "
<h4>Poverty status</h4>
<p>Each sample person was classified according to the total annual income of his or her family. Possible sources of income included annual earnings from wages, salaries, bonuses, tips, and commissions; business and farm gains and losses; unemployment and Worker's Compensation; interest and dividends; alimony, child support, and other private cash transfers; private pensions, individual retirement account (IRA) withdrawals, Social Security, and Department of Veterans Affairs payments; Supplemental Security Income and cash welfare payments from public assistance, Aid to Families with Dependent Children and Aid to Dependent Children; gains or losses from estates, trusts, partnerships, S corporations, rent, and royalties; and a small amount of 'other' income. Poverty status is the ratio of family income to the corresponding federal poverty thresholds, which control for family size and age of the head of family. Categories are defined as follows:</p>
<ul>
  <li><i>Negative or Poor</i>: Household income below the Federal poverty line.</li>

  <li><i>Near poor</i>: Household income over the poverty line through 125 percent of the poverty line.</li>

  <li><i>Low income</i>: Household income 125 percent through 200 percent of the poverty line.</li>

  <li><i>Middle income</i>: over 200 percent to 400 percent of the poverty line.</li>

  <li><i>High income</i>: over 400 percent of the poverty line.</li>
</ul>
"

notes$race <- notes$racesex <- "
<h4>Race/ethnicity</h4>
<p>Classification by race and ethnicity is based on information reported for each family member. Starting in 2002, specifications changed so that individuals could report multiple races. Respondents were asked if the race of the sample person was best described as American Indian, Alaska Native, Asian or Pacific Islander, black, white, or other. Prior to 2002, race categories in the tables for American Indian, Alaska Native, Asian or Pacific Islander, multiple races, white, and other are collapsed into the single category of <i>White and other</i>.</p>

<p>For all years, respondents were asked if the sample person's main national origin or ancestry was Puerto Rican; Cuban; Mexican, Mexicano, Mexican American, or Chicano; other Latin American; or other Spanish. All persons whose main national origin or ancestry was reported in one of these Hispanic groups, regardless of racial background, are classified as Hispanic. Since the Hispanic grouping can include black Hispanic, white Hispanic, and other Hispanic, the race categories of black, white, and other do not include Hispanic people.</p>
"

# Event types are different based on app ('Other medical' not included in conditions app)
ul_event <- "
<h4>Event type</h4>
<ul>
  <li><i>Physician office visits</i> and <i>Non-physician office visits</i> are sub-categories of <i>Office-based events</i>.</li>
  <li><i>Physician hosp. visits</i> and <i>Non-physician hosp. visits</i> are sub-categories of <i>Outpatient events</i>.</li>
  <li>A <i>home health event</i> is defined as one month during which home health service was received.</li>
  <li>For <i>prescription medicines</i>, an event is defined as a purchase or refill.</li>
  %s
</ul>
"

notes$use$event <- sprintf(ul_event,
  '<li><i>Other medical equipment and services</i> are expenses for medical equipment such as eyeglasses, hearing aids, or wheelchairs.</li>')

notes$cond$event <- sprintf(ul_event,"")



# Accessibility and Quality of Care --------------------------------------------------------

notes$usc <- "
<h4>Usual source of care</h4>
For each individual family member, the respondent is asked whether there is a particular doctor's office, clinic, health center, or other place that the individual usually goes to if he/she is sick or needs advice about his/her health.
"

notes$diab_foot <- "
<h4>Foot care</h4>
Starting in 2008, the questionnaire for foot care changed slightly, splitting
<i>No exam in past year</i> into exam <i>More than 1 year ago</i> and
<i>Never had feet checked</i>.
"
notes$diab_eye <- "
<h4>Eye exam</h4>
A small percentage of persons (< 0.1 percent) had a missing or invalid response for eye exam.
"

notes$difficulty <- "
<h4>Difficulty receiving needed care</h4>
Difficulty categories are not mutually exclusive. For instance, a person can have difficulty obtaining both medical and dental care.
"

notes$rsn_ANY <- notes$rsn_MD <- notes$rsn_DN <- notes$rsn_PM <- "
<h4>Reasons for difficulty receiving needed care</h4>
Reasons for difficulty are not mutually exclusive. For instance, a person can have difficulty due to insurance-related issues as well as affordability.
"

# Medical Conditions  --------------------------------------------------------

notes$Condition <- "
<h4>Conditions</h4>
<p>Medical conditions are based on conditions for which treatment was received, where treatment includes emergency room visits, home health care, inpatient stays, office-based visits, outpatient visits, and prescription medicine purchases. <i>Other medical equipment and services</i> and <i>dental visits</i> are not included in these tables since medical conditions are not collected for these event types.</p>

<p>Starting in 2007, new survey questions were introduced into MEPS asking participants about whether they had been told they have certain priority health conditions. This change in the survey methodology may have impacted responses for utilization and expenditures related to the following conditions: hypertension, heart disease, cerebrovascular disease, COPD, asthma, hyperlipidemia, cancer, diabetes mellitus, and osteoarthritis. Care should be taken when analyzing these conditions over a time period that spans the 2007 change in survey methodology.</p>

<p>Details on how condition categories are created can be found in the <a href = https://meps.ahrq.gov/data_stats/conditions.shtml>Condition Categories</a> information table.</p>
"

# Prescribed Drugs ------------------------------------------------------------

notes$RXDRGNAM <- "
Data source for generic drug name is Cerner Multum Inc.
"

notes$TC1name <- '
<p>Data source for therapeutic class is Cerner Multum Inc.</p>

<p>The overwhelming majority of items in the "Not Ascertained" category are medical supplies and devices, such as test strips, lancets, and glucometers.</p>

<p>Users should be cautious when assessing trends in therapeutic classes, because Multum\'s therapeutic classification has changed across the years of the MEPS. The Multum variables on each year of this table reflect the most recent classification available in the year the MEPS Prescribed Medicines files were originally released. Since the release of the 1996 Prescribed Medicines file, the Multum classification has been changed by the addition of new classes, and by drugs switching classes. For example: 1) In 1996-2004, antidiabetic drugs were a subclass of the hormone class, but in subsequent years, the antidiabetic subclass is part of a class of metabolic drugs. 2) In 1996-2004, antihyperlipidemic agents were categorized as a class. In subsequent files, antihyperlipidemic drugs were a subclass in the metabolic class. 3) In 1996-2004, the psychotherapeutic class comprised drugs from four subclasses: antidepressants, antipsychotics, anxiolytics/sedatives/hypnotics, and CNS stimulants. In subsequent files, the psychotherapeutic class comprised only antidepressants and antipsychotics.</p>'
