# setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(htmltools)
library(tidyverse)
library(shiny)

source("app_info_hc.R")
source("functions.R")
source("functions_toHTML.R")


## !! hc_year is defined in UPDATE.R


# AHRQ header and footer ------------------------------------------------------

ahrq_meta <- HTML(readSource("../html/ahrq_meta.html"))
ahrq_header <- HTML(readSource("../html/ahrq_header.html"))
ahrq_footer <- HTML(readSource("../html/ahrq_footer.html"))

# Home Page -------------------------------------------------------------------

dir.create("../mepstrends/home/")

# limit to just hc tables for now
hc_info <- infoList[names(infoList) %>% startsWith("hc")]

navbar <- tagList(lapply(names(hc_info), navbar_items))

home_body <- tagList(
  div(class = "usa-grid full-screen info-box",
    div(class = "em-container",
      h2("Household Component summary tables"),
      tags$p(HTML(infoList[['home']][['description']]))
      )
    ),

  div(class = 'usa-grid full-screen bottom-half',
      div(class = 'em-container',
        fluidRow(
          column(width = 4, preview_box('hc_use')),
          column(width = 4, preview_box('hc_ins')),
          column(width = 4, preview_box('hc_care'))
        ),
        fluidRow(
          column(width = 4, preview_box('hc_cond')),
          column(width = 4, preview_box('hc_cond_icd10')),
          column(width = 4, preview_box('hc_pmed')),
          column(width = 4)
        )
      )
  )

)

home_page <- htmltools::htmlTemplate(
  "../html/template.html", body = home_body, load_js = "", navbar = navbar,
  ahrq_meta = ahrq_meta, ahrq_header = ahrq_header, ahrq_footer = ahrq_footer)

write(as.character(home_page), file = '../mepstrends/home/index.html')


## HC TABLES ------------------------------------------------------------------

# Use, expenditures, and population characteristics ---------------------------

cat("hc_use...")
dir.create("../mepstrends/hc_use/")
year_list = 1996:hc_year

load("../formatted_tables/hc_use/hc_use.Rdata") # MASTER_TABLE

use_forms <- tagList(
  statInput(MASTER_TABLE),
  tags$div(id = "control-totals",
           "(Standard errors are approximately zero for control totals)"),
  dataViewInput(),
  yearInput(year_list),
  rcInput(MASTER_TABLE, type = 'col', label = 'Group by (columns):'),
  tags$fieldset(
    class = 'hide-if-trend',
    rcInput(MASTER_TABLE, type = 'row', label = 'Group by (rows):'),
    actionButton508("switchRC", label = "Switch rows/columns"))
)

use_page <- build_html('hc_use', forms = use_forms, pivot = F)
write(as.character(use_page), file = "../mepstrends/hc_use/index.html")


# Health insurance ------------------------------------------------------------

cat("hc_ins...")
dir.create("../mepstrends/hc_ins/")
year_list = 1996:hc_year

load("../formatted_tables/hc_ins/hc_ins.Rdata")

ins_forms <- tagList(
  statInput(MASTER_TABLE),
  rcInput(MASTER_TABLE, type = "col", label = "Select variable:"),
  dataViewInput(),
  yearInput(year_list),
  tags$fieldset(
    class = 'hide-if-trend',
    rcInput(MASTER_TABLE, type = "row"))
)

ins_page <- build_html('hc_ins', forms = ins_forms, pivot = F)
write(as.character(ins_page), file = "../mepstrends/hc_ins/index.html")


# Accessibility and quality of care -------------------------------------------

cat("hc_care...")
dir.create("../mepstrends/hc_care/")
year_list = 2002:hc_year

load("../formatted_tables/hc_care/hc_care.Rdata")

care_forms <- tagList(
  statInput(MASTER_TABLE),
  rcInput(MASTER_TABLE, type = "col", label = "Select variable:"),
  dataViewInput(),
  yearInput(year_list),
  tags$fieldset(
    class = 'hide-if-trend',
    rcInput(MASTER_TABLE, type = "row"))
)

care_page <- build_html('hc_care', forms = care_forms, pivot = F)
write(as.character(care_page), file = "../mepstrends/hc_care/index.html")


# Prescribed Drugs ------------------------------------------------------------

cat("hc_pmed...")
dir.create("../mepstrends/hc_pmed/")
year_list = 1996:hc_year

load("../formatted_tables/hc_pmed/hc_pmed.Rdata")

pmed_forms <- tagList(
  statInput(MASTER_TABLE),
  rcInput(MASTER_TABLE, type = "row", level_select = F),
  yearInput(year_list),
  div(class = 'hidden',
      rcInput(MASTER_TABLE, type = "col", level_select = F))
)

pmed_page <- build_html('hc_pmed', forms = pmed_forms, pivot = T)
write(as.character(pmed_page), file = "../mepstrends/hc_pmed/index.html")


# Medical Conditions (1996 - 2015) --------------------------------------------

# adding these notes statically so the external-link works

cond_notes <- HTML("
<h4>Conditions</h4>
<p>Medical conditions are based on conditions for which treatment was received, where treatment includes emergency room visits, home health care, inpatient stays, office-based visits, outpatient visits, and prescription medicine purchases. <i>Other medical equipment and services</i> and <i>dental visits</i> are not included in these tables since medical conditions are not collected for these event types.</p>

<p>Several changes have occurred in the collection and processing of MEPS condition data that may impact analysis of trends over time:
</p>

<p>(1) Starting in 2007, new survey questions were introduced into MEPS asking participants about whether they had been told they have certain priority health conditions. This change in the survey methodology may have impacted responses for utilization and expenditures related to the following conditions: hypertension, heart disease, cerebrovascular disease, COPD, asthma, hyperlipidemia, cancer, diabetes mellitus, and osteoarthritis.</p>

<p>(2) From 1996-2015, household-reported medical conditions were coded into ICD-9 and CCS codes, which were then collapsed into broad Condition categories. Starting in 2016, household-reported medical conditions were coded into ICD-10 and CCSR codes before collapsing into Condition categories. This discontinuity is presented in separate table series. Extreme care must be taken when comparing data on medical conditions before and after this transition, due to fundamental differences between the ICD-9 and ICD-10 codes, as well as the CCS and CCSR codes. In addition, several of the collapsed condition categories in the MEPS Summary Tables have been updated. For example, \"Appendicitis\" and \"Other GI\" conditions are now included in the \"Other stomach and intestinal disorders\" category.</p>  

<p>The transition from ICD9/CCS codes to ICD10/CCSR codes is an ongoing process. The data in these tables may be updated whenever updated CCSR codes are released. Crosswalks between the CCS[R] and collapsed Condition categories can be found at the 
<a class='external-link' href='https://github.com/HHS-AHRQ/MEPS/tree/master/Quick_Reference_Guides' target='_blank_'>AHRQ GitHub site
<img src='../src/custom/img/externallink.gif' alt='External Link'></a>


More information on CCS[R] coding can be found at the HCUP website: 
<ul>
  <li>
    ICD9/CCS:  <a href = https://www.hcup-us.ahrq.gov/toolssoftware/ccs/ccs.jsp>https://www.hcup-us.ahrq.gov/toolssoftware/ccs/ccs.jsp</a> 
  </li>
  <li>
    ICD10/CCSR:  <a href = https://www.hcup-us.ahrq.gov/toolssoftware/ccsr/ccs_refined.jsp>https://www.hcup-us.ahrq.gov/toolssoftware/ccsr/ccs_refined.jsp</a> 
  </li>
</ul>
</p>

")


cat("hc_cond...")
dir.create("../mepstrends/hc_cond/")
year_list = 1996:2015

load("../formatted_tables/hc_cond/hc_cond.Rdata")

cond_forms <- tagList(
  statInput(MASTER_TABLE),
  dataViewInput(),
  yearInput(year_list),
  tags$fieldset(
    class = 'hide-if-trend',
    rcInput(MASTER_TABLE, type = "col")),
  div(class = 'hidden',
      rcInput(MASTER_TABLE, type = "row", level_select = F))
)

cond_page <- build_html('hc_cond', forms = cond_forms, pivot = T, app_notes = cond_notes)
write(as.character(cond_page), file = "../mepstrends/hc_cond/index.html")


# Medical Conditions (2016 - current) -----------------------------------------

cat("hc_cond_icd10...")
dir.create("../mepstrends/hc_cond_icd10/")
year_list = 2016:hc_year

load("../formatted_tables/hc_cond_icd10/hc_cond_icd10.Rdata")

cond_forms <- tagList(
  statInput(MASTER_TABLE),
  dataViewInput(),
  yearInput(year_list),
  tags$fieldset(
    class = 'hide-if-trend',
    rcInput(MASTER_TABLE, type = "col")),
  div(class = 'hidden',
      rcInput(MASTER_TABLE, type = "row", level_select = F))
)

cond_icd10_page <- build_html('hc_cond_icd10', forms = cond_forms, pivot = T, 
                              include = c("table", "plot"), app_notes = cond_notes)

write(as.character(cond_icd10_page), file = "../mepstrends/hc_cond_icd10/index.html")
