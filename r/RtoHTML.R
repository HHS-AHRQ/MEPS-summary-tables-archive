setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(htmltools)
library(dplyr)
library(shiny)

source("functions.R")
source("dictionaries.R")

# AHRQ header and footer ------------------------------------------------------

ahrq_meta <- HTML(readSource("../html/ahrq_meta.html"))
ahrq_header <- HTML(readSource("../html/ahrq_header.html"))
ahrq_footer <- HTML(readSource("../html/ahrq_footer.html"))

# HOME PAGE -------------------------------------------------------------------

hc_items <- function(appKey) {
  info <- infoList[[appKey]]
  tags$a(class = "dropdown-item", #href = sprintf("../hc_%s/index.html", appKey),
         href = sprintf("../hc_%s/", appKey),
         tags$span(info$title))
}

hc_navbar <- tagList(lapply(names(infoList), hc_items))

preview_box <- function(appKey) {
  info <- infoList[[appKey]]

    div(
        tags$a(
          #href = sprintf("../hc_%s/index.html",appKey),
          href = sprintf("../hc_%s/",appKey),
          class = "preview-box",
          tags$img(src = info$img$src, alt = info$img$alt,  width = '75px'),
          h3(info$title), tags$p(info$preview))
  )
}


home_body <- tagList(
  div(class = "usa-grid full-screen info-box",
  div(class = "em-container",
  h2("Household Component summary tables"),
  tags$p(HTML(paste(
  'The MEPS Household Component summary tables provide frequently used summary estimates for the U.S. civilian noninstitutionalized population on household medical utilization and expenditures, demographic and socio-economic characteristics, health insurance coverage, access to care and satisfaction with care, medical conditions, and prescribed medicine purchases. Most tables can be stratified by demographic or socio-economic characteristics. Plots from selected data can also be generated, and R and SAS code for calculating selected estimates is available. See',
  tags$a(href = "https://meps.ahrq.gov/mepsweb/survey_comp/hc_data_collection.jsp",
  "Sample Design and Data Collection Process"),
  'for details on the collection of individual data items (e.g., health insurance status, age). The estimates provided in the tables are based on data available in standardized',
  tags$a(href = "https://meps.ahrq.gov/mepsweb/data_stats/download_data_files.jsp",
  "public use data files."),
  'Pages have been optimized for Chrome, Firefox, and Safari.')
  ))
  )),

  div(class = 'usa-grid full-screen bottom-half',
      div(class = 'em-container',
        fluidRow(
          column(width = 4, preview_box('use')),
          column(width = 4, preview_box('ins')),
          column(width = 4, preview_box('care'))
        ),
        fluidRow(
          column(width = 4, preview_box('cond')),
          column(width = 4, preview_box('pmed')),
          column(width = 4)
        )
      )
  )

)

home_page <- htmltools::htmlTemplate(
  "../html/template.html", body = home_body, load_js = "", hc_navbar = hc_navbar,
  ahrq_meta = ahrq_meta, ahrq_header = ahrq_header, ahrq_footer = ahrq_footer)

write(as.character(home_page), file = '../mepstrends/home/index.html')


# Summary Tables --------------------------------------------------------------

build_body <- function(info, forms, main) {
  tagList(
    div(class = 'info-box ',
        div(class='full-screen',
            h2(info$title, tags$img(src = info$img$src, alt = info$img$alt, class = "app-image")),
            p(info$description),
            p(HTML(info$instructions1)),
            p(HTML(info$instructions2)))),

    fluidRow(class = "full-screen",
             column(id = "meps-form-container", width=12, class="col-md-3",
                    tags$form(class = "usa-form-large", forms)),

             column(width=12,class="col-md-9",main)
    )
  )
}


build_main <- function(pivot = F) {
  tagList(
  tags$ul(id = "meps-tabs", class = "nav nav-pills",
          tab_li('table', "Table", class = 'active'),
          tab_li('plot', "Plot"),
          tab_li('code', "Code")),

  div(class = 'tab-content',

    # TABLE -----------------------------------------------------------
      div(id = 'table-tab', class = 'tab-pane active',
          div(class = 'caption-block',
            downloadButton508('dl-table', "Download table"),
            caption('table')
          ),

          if(pivot) {
            tagList(
              tags$p(
                tags$i("To activate the 'plot' tab, select up to 10 rows by clicking in the table below.")),
              searchBox508('search', 'Search rows:'),
              actionButton508('sort-selected', class = 'select-button', label = 'Sort by selected'),
              actionButton508('deselect', class = 'select-button', label = 'Clear selected')
            )
          },

          div(id = 'loading', 'Loading data...'),
          tags$table(id = 'meps-table', cellspacing = '0', width = '100%'),

          tags$div(id = "table-footnotes", role = "region", 'aria-live' = "polite",
            tags$aside(id = "suppress",
              HTML(sprintf(' -- Estimates suppressed due to inadequate precision (see %s for details).',
                  tags$a("FAQs", target = "_blank_", href="https://meps.ahrq.gov/survey_comp/precision_guidelines.shtml")
                ))
            ),

            tags$aside(id = "RSE", "* Relative standard error is greater than 30%")
          )

      ),

    # PLOT ----------------------------------------------------
      div(id = 'plot-tab', class = 'tab-pane',
          div(class = 'caption-block plot-dependent',
            downloadButton508('dl-plot', "Download plot"),
            caption('plot')
          ),

          if(pivot){
            div(id = 'select-rows-message',
              tags$p(
                tags$i("Please choose items to plot by selecting rows under the Table tab.")))
          },

          div(id = 'meps-plot', class = 'plot-dependent'),
          div(id = 'plot-warning', "No non-missing data available for selections. Please try again."),
          div(id = "plot-footnotes", class = "in-front plot-dependent",
              role = "region", 'aria-live' = "polite",
              tags$aside(id = "plot-suppress",
                HTML(sprintf('Some estimates suppressed due to inadequate precision (see %s for details).',
                             tags$a("FAQs", target = "_blank_", href="https://meps.ahrq.gov/survey_comp/precision_guidelines.shtml")
                ))
              )
          )
      ),

    # CODE ---------------------------------------------------
      div(id = 'code-tab', class = 'tab-pane',
          div(class = 'code-select',
              selectInput508('code-language', label = "Select programming language:",
                             choices = c("R", "SAS")),
              downloadButton508('dl-code', 'Download code')
              ),

          tags$p(HTML('To run the code, first download and unzip the required public use data files from the
              <a href="https://meps.ahrq.gov/mepsweb/data_stats/download_data_files.jsp" target="_blank_">MEPS
              data files page</a>, and save them to your computer. More information on downloading and analyzing
              MEPS data in R, SAS, and Stata can be found at the <a class="external-link"
              href="https://github.com/HHS-AHRQ/MEPS#accessing-meps-hc-data" target="_blank_">AHRQ GitHub site
              <img src="../src/custom/img/externallink.gif" alt="External Link"></a>. Note that some standard
              error estimates may differ between R and SAS, since SAS doesn\'t support any options to adjust for
              lonely PSUs.')),

          tags$p("The following code can be used to generate the selected estimates, where the SAS transport data
                 files (.ssp) have been saved to the folder 'C:\\MEPS'. For trend estimates, example code is shown
                 for the most recent year selected:"),

          tags$pre(id = 'code', role = 'region', 'aria-live' = 'polite')
      )
    ),

  # NOTES --------------------------------------------------------------------
  div(id = 'hc-info',
      div(id = 'source', class = 'in-front'),

      h3('Notes'),
        div(id = 'notes', role = 'region', "aria-live" = 'polite'),
        tags$p("This tool is provided as a convenience. It is the responsibility of the user to review
        results for statistical significance and overall reasonableness."),

      h3("About the data"),
       tags$p("The MEPS Household Component collects data on all members of sample households
        who are in-scope for the survey.  These data can be used to produce nationally
        representative estimates of medical conditions, health status, use of medical
        care services, charges and payments, access to care, satisfaction with care,
        health insurance coverage, income, and employment. The target population
        represented in the tables and figures is persons in the U.S. civilian
        non-institutionalized population for all or part of the year."),

      h3("Suggested citation"),
        div(id = 'citation'))
  )
}

build_html <- function(appKey, forms, pivot = F) {

  load_js <- tagList(
    tags$script(src = '../src/custom/js/functions.js'),
    tags$script(src = 'json/init.js'),
    tags$script(src = 'json/code.js'),
    tags$script(src = '../src/custom/js/em.js')
  )

  body <- build_body(infoList[[appKey]], forms = forms, main = build_main(pivot = pivot))
  htmlTemplate("../html/template.html", body = body, load_js = load_js, hc_navbar = hc_navbar,
               ahrq_meta = ahrq_meta, ahrq_header = ahrq_header, ahrq_footer = ahrq_footer)
}

# Form components -------------------------------------------------------------

statInput <- function(appKey) {
  tagList(
    selectInput508("stat", choices = statList[[appKey]], label = "Select statistic:"),
    checkboxInput508("showSEs", label="Show standard errors")
  )
}

dataViewInput <-
  radioButtons508(
    "data-view", "Select data view:", inline = T,
    class = "em-fieldset",
    choices = c("Trends over time" = "trend", "Cross-sectional" = "cross"))

yearInput <- function(year_list) {
  tags$fieldset(
    tags$legend("Select years",class = 'usa-sr-only'),
    div(class = "flex-parent",
        div(class="flex-child-fill year-start",
            selectInput508("year-start", label = "Year:", choices = rev(year_list), selected = min(year_list))),
        div(class="flex-child-fill year-main",
            selectInput508("year", label = "to:", choices = rev(year_list), selected = max(year_list)))
    )
  )
}

rcInput <-
  function(appKey, type, label="Group by:", class = "", hide_label = F, level_select = T) {
    grps = get(sprintf("%sGrps",type))
    tags$fieldset(
      class = class,
      tags$label(label, `for` = sprintf("%sGrp", type), class = ifelse(hide_label, "usa-sr-only", "")),
      div(role = "group",

          div(role = "group",
              selectInput508(sprintf("%sGrp", type), choices = grps[[appKey]])),

          if(level_select) {
            div(
                dropdown508(
                  sprintf("%sDrop",type), label = 'Select Levels',
                  checkboxGroupInput508(sprintf("%sLevels", type)),
                  actionButton508(sprintf("%sReset", type), label = "Reset", usaStyle = "outline")
                ))
          }

      ))
  }


# Use, expenditures, and population characteristics ---------------------------

year_list = 1996:2015

use_forms <- tagList(
  statInput('use'),
  tags$div(id = "control-totals",
           "(Standard errors are approximately zero for control totals)"),
  dataViewInput,
  yearInput(year_list),
  rcInput('use', type = 'col', label = 'Group by (columns):'),
  tags$fieldset(
    class = 'hide-if-trend',
    rcInput("use", type = 'row', label = 'Group by (rows):'),
    actionButton508("switchRC", label = "Switch rows/columns"))
)

use_page <- build_html('use', forms = use_forms, pivot = F)
write(as.character(use_page), file = "../mepstrends/hc_use/index.html")

# Health insurance ------------------------------------------------------------

year_list = 1996:2015

ins_forms <- tagList(
  statInput('ins'),
  rcInput("ins", type = "col", label = "Select variable:"),
  dataViewInput,
  yearInput(year_list),
  tags$fieldset(
    class = 'hide-if-trend',
    rcInput("ins", type = "row"))
)

ins_page <- build_html('ins', forms = ins_forms, pivot = F)
write(as.character(ins_page), file = "../mepstrends/hc_ins/index.html")


# Accessibility and quality of care -------------------------------------------

year_list = 2002:2015

care_forms <- tagList(
  statInput('care'),
  rcInput("care", type = "col", label = "Select variable:"),
  dataViewInput,
  yearInput(year_list),
  tags$fieldset(
    class = 'hide-if-trend',
    rcInput("care", type = "row"))
)

care_page <- build_html('care', forms = care_forms, pivot = F)
write(as.character(care_page), file = "../mepstrends/hc_care/index.html")


# Prescribed Drugs ------------------------------------------------------------

year_list = 1996:2015

pmed_forms <- tagList(
  statInput('pmed'),
  rcInput("pmed", type = "row", level_select = F),
  yearInput(year_list),
  div(class = 'hidden',
      rcInput("pmed", type = "col", level_select = F))
)

pmed_page <- build_html('pmed', forms = pmed_forms, pivot = T)
write(as.character(pmed_page), file = "../mepstrends/hc_pmed/index.html")


# Medical Conditions -----------------------------------------------------------

year_list = 1996:2015

cond_forms <- tagList(
  statInput('cond'),
  dataViewInput,
  yearInput(year_list),
  tags$fieldset(
    class = 'hide-if-trend',
    rcInput("cond", type = "col")),
  div(class = 'hidden',
      rcInput("cond", type = "row", level_select = F))
)

cond_page <- build_html('cond', forms = cond_forms, pivot = T)
write(as.character(cond_page), file = "../mepstrends/hc_cond/index.html")
