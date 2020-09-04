# HTML builder functions ------------------------------------------------------

rm_spec <- function(str) gsub("[^[:alnum:]]","",str) %>% tolower

subGrp_builder <- function(MASTER_TABLE) {
  sG <- MASTER_TABLE$subGrp %>% unique %>% pop("", NA)
  sG_radioButtons <- list()
  for(grp in sG) {
    this_sG <- MASTER_TABLE %>% filter(subGrp == grp)
    label <- this_sG$subGrp_label %>% unique
    if(length(label) > 1) stop("Too many labels for subgroup category")

    options <- this_sG$subLevels %>% unique
    choices <- rm_spec(options) %>% setNames(options)

    sG_radioButtons[[grp]] <-
      radioButtons508(
        inputId = rm_spec(grp),
        class = 'subgrp',
        label = label,
        choices = choices
      )
  }
  tagList(sG_radioButtons)
}



getChoices <- function(MASTER_TABLE, var, label, grp = "") {
  if(grp == "" | !grp %in% colnames(MASTER_TABLE)) {
    ss <- MASTER_TABLE %>% select_(var, label) %>% unique
    varlist <- ss[,var] %>% setNames(ss[,label])
  } else {
    ss <- MASTER_TABLE %>% select_(var, grp, label) %>% unique
    varlist <- list()
    for(grpName in unique(ss[,grp])) {
      this_grp = ss %>% filter_(sprintf('%s == "%s"', grp, grpName))

      if(grpName == "") {
        labName <- this_grp[,label]
        varlist[[labName]] <- this_grp[,var]
      } else {
        varlist[[grpName]] <- this_grp[,var] %>% setNames(this_grp[,label])
      }
    }
  }
  return(varlist)
}

statInput <- function(MASTER_TABLE) {
  choices <- getChoices(MASTER_TABLE, var = 'stat_var', grp = 'stat_group', label = 'stat_label')
  tagList(
    selectInput508("stat_var", choices = choices, label = "Select statistic:"),
    checkboxInput508("showSEs", label="Show standard errors")
  )
}



rcInput <- function(MASTER_TABLE, type, label="Group by:", class = "", hide_label = F, level_select = T) {

  choices <- getChoices(MASTER_TABLE,
                        var = paste0(type,"_var"),
                        grp = paste0(type,"_group"),
                        label = paste0(type,"_label"))

  tags$fieldset(
    class = class,
    tags$label(label, `for` = sprintf("%s_var", type),
               class = ifelse(hide_label, "usa-sr-only", "")),

    div(role = "group",

        div(role = "group",
            selectInput508(sprintf("%s_var", type), choices = choices)),

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



# Home page -------------------------------------------------------------------

navbar_items <- function(appKey) {
  info <- infoList[[appKey]]
  tags$a(class = "dropdown-item", #href = sprintf("../%s/index.html", appKey),
         href = sprintf("../%s/", appKey),
         tags$span(info$title))
}


preview_box <- function(appKey) {
  info <- infoList[[appKey]]

  div(
    tags$a(
      #href = sprintf("../hc_%s/index.html",appKey),
      href = sprintf("../%s/",appKey),
      class = "preview-box",
      tags$img(src = info$img$src, alt = info$img$alt,  width = '75px'),
      h3(info$title), tags$p(info$preview))
  )
}


# Summary tables pages --------------------------------------------------------

build_body <- function(info, forms, main) {
  tagList(
    div(class = 'info-box ',
        div(class='full-screen',
            h2(info$title, tags$img(src = info$img$src, alt = info$img$alt, class = "app-image")),
            tags$p(info$description),
            tags$p(HTML(info$instructions1)),
            tags$p(HTML(info$instructions2)))),

    fluidRow(class = "full-screen",
             column(id = "meps-form-container", width=12, class="col-md-3",
                    tags$form(class = "usa-form-large", forms)),

             column(width=12,class="col-md-9",main)
    )
  )
}


build_table <- function(pivot, include_DNC = FALSE) {
  suppressed_HTML <-
    sprintf(
      ' -- Estimates suppressed due to inadequate precision (see %s for details).',
      tags$a(
        "FAQs", target = "_blank_",
        href="https://meps.ahrq.gov/survey_comp/precision_guidelines.shtml"))


  div(id = 'table-tab', class = 'tab-pane active',
      div(class = 'caption-block',
          downloadButton508('dl-table', "Download table"),
          caption('table')
      ),

      if(pivot) {
        tagList(
          tags$p(
            tags$i(
              "To activate the 'plot' tab, select up to 10 rows by clicking in the table below.")),
          searchBox508('search', 'Search rows:'),
          actionButton508('sort-selected', class = 'select-button', label = 'Sort by selected'),
          actionButton508('deselect', class = 'select-button', label = 'Clear selected')
        )
      },

      div(id = 'loading', 'Loading data...'),
      tags$table(id = 'meps-table', cellspacing = '0', width = '100%'),

      tags$div(
        id = "table-footnotes", role = "region", 'aria-live' = "polite",
        tags$aside(id = "suppress", HTML(suppressed_HTML)),
        tags$aside(id = "RSE", "* Relative standard error is greater than 30%"),
        if(include_DNC) {
          tags$aside(
            id = "DNC", 
            HTML("DNC: Data not collected. The MEPS survey instrument re-design in 2018 affected some of the \"Access to Care\" and \"Quality of Care\" variables. Some of these variables will be collected every other year, while others were completely dropped from the survey and are no longer collected. Please refer to the 
                 <a href = 'https://meps.ahrq.gov/data_stats/download_data/pufs/h209/h209doc.shtml'>
                 2018 Full-Year File Documentation
                 </a>
                 and 
                 </a href = 'https://meps.ahrq.gov/mepsweb/survey_comp/survey.jsp#Questionnaires'>
                 Survey Questionnaires
                 </a> for more details."))
        }
      )
  )
}

build_plot <- function(pivot) {
  suppressed_HTML <-
    sprintf(
      'Some estimates suppressed due to inadequate precision (see %s for details).',
      tags$a(
        "FAQs", target = "_blank_",
        href="https://meps.ahrq.gov/survey_comp/precision_guidelines.shtml"))

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
          tags$aside(id = "plot-suppress", HTML(suppressed_HTML))
      )
  )
}

build_code <- function(pivot) {
  # CODE ---------------------------------------------------
  div(id = 'code-tab', class = 'tab-pane',
      div(class = 'code-select',
          selectInput508('code-language',
                         label = "Select programming language:",
                         choices = c("R", "SAS")),
          downloadButton508('dl-code', 'Download code')
      ),

      tags$p(HTML(
  'To run the code, first download and unzip the required public use data files from the
  <a href="https://meps.ahrq.gov/mepsweb/data_stats/download_data_files.jsp" target="_blank_">MEPS
  data files page</a>, and save them to your computer. More information on downloading and analyzing
  MEPS data in R, SAS, and Stata can be found at the <a class="external-link"
  href="https://github.com/HHS-AHRQ/MEPS#accessing-meps-hc-data" target="_blank_">AHRQ GitHub site
  <img src="../src/custom/img/externallink.gif" alt="External Link"></a>. Note that some standard
  error estimates may differ between R and SAS, since SAS doesn\'t support any options to adjust for
  lonely PSUs.')),

      tags$p(
  "The following code can be used to generate the selected estimates, where the SAS transport data
  files (.ssp or .sas7bdat) have been saved to the folder 'C:\\MEPS'. For trend estimates, example code is shown
  for the most recent year selected:"),

      tags$pre(id = 'code', role = 'region', 'aria-live' = 'polite')
  )

}


build_main <- function(pivot = F, include = c("table", "plot", "code"), app_notes = "",...) {
  tagList(
    tags$ul(
      id = "meps-tabs", class = "nav nav-pills",
      if("table" %in% include) { tab_li('table', "Table", class = 'active') },
      if("plot" %in% include) { tab_li('plot', "Plot") },
      if("code" %in% include) { tab_li('code', "Code") }
      ),

    div(class = 'tab-content',
        div(id = 'updating-overlay',
            div(id = 'updating-text', 'Updating, please wait...')),

        if("table" %in% include) { build_table(pivot,...) },
        if("plot"  %in% include) { build_plot(pivot) },
        if("code"  %in% include) { build_code(pivot) }
    ),

    # NOTES --------------------------------------------------------------------
    div(id = 'hc-info',
        div(id = 'source', class = 'in-front'),

        h3('Notes'),
        div(id = 'notes', role = 'region', "aria-live" = 'polite'),

        app_notes,

        tags$p("This tool is provided as a convenience. It is the responsibility of the user to review
               results for statistical significance and overall reasonableness."),

        h3("About the data"),
        tags$p("The MEPS Household Component collects data on all members of sample households
               who are in-scope for the survey.  These data can be used to produce nationally
               representative estimates of medical conditions, health status, use of medical
               care services, charges and payments, access to care, experience with care,
               health insurance coverage, income, and employment. The target population
               represented in the tables and figures is persons in the U.S. civilian
               non-institutionalized population for all or part of the year."),

        h3("Suggested citation"),
        div(id = 'citation'))
        )
}

build_html <- function(appKey, forms, pivot = F, include = c("table", "plot"),...) {

  load_js <- tagList(
    tags$script(src = '../src/custom/js/functions.js'),
    tags$script(src = 'json/init.js'),
    tags$script(src = 'json/notes.js'),
    tags$script(src = '../src/custom/js/em.js')
  )

  body <- build_body(
    infoList[[appKey]],
    forms = forms,
    main = build_main(pivot = pivot, include = include,...))

  htmlTemplate("../html/template.html", body = body, load_js = load_js, navbar = navbar,
               ahrq_meta = ahrq_meta, ahrq_header = ahrq_header, ahrq_footer = ahrq_footer)
}


# Form components -------------------------------------------------------------


dataViewInput <- function() {
  radioButtons508(
    "data-view", "Select data view:", inline = T,
    class = "em-fieldset",
    choices = c("Trends over time" = "trend", "Cross-sectional" = "cross"))
}

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




# 508 form functions and html builder -----------------------------------------------

tab_li <- function(id, label, class = "") {
  tags$li(class = class,
          tags$a('data-toggle' = 'tab', href = sprintf('#%s-tab',id), id = sprintf('%s-pill',id),
                 tags$span(class = sprintf("tab-title %s-tab",id), label)))
}

caption <- function(id) {
  tags$span(id = sprintf('%s-caption',id), role = 'region', 'aria-live' = 'polite', class = 'caption')
}

actionButton508 <- function (inputId, label, usaStyle = NULL, class="", icon = NULL, width = NULL, ...){
  value <- restoreInput(id = inputId, default = NULL)
  tags$button(
    id = inputId,
    type = "button",
    class = sprintf("action-button %s",class),
    class = paste(c("usa-button", usaStyle),collapse="-"),
    `data-val` = value,
    list(icon, label), ...)
}


selectInput508 <- function (inputId, choices = "", selected = NULL, label=NULL, width = NULL, size = NULL){
  choices <- choicesWithNames(choices)
  if(is.null(selected)) {
    selected <- firstChoice(choices)
  }else{
    selected <- as.character(selected)
  }

  selectTag <- tags$select(id = inputId, size = size, selectOptions(choices, selected))
  labelTag <- if(!is.null(label)) tags$label(label, 'for'=inputId)

  tagList(labelTag, selectTag)
}

checkboxInput508 <- function(inputId, label, value = FALSE, inline=FALSE, class=""){
  inputTag <- tags$input(id = inputId, type = "checkbox", name=inputId, value=inputId,class=class)
  if (!is.null(value) && value) inputTag$attribs$checked <- "checked"
  labelTag <- tags$label('for'=inputId,label)
  if(inline){
    inputTag$attribs$style = 'display: inline;'
    labelTag$attribs$style = 'display: inline;'
  }
  tagList(inputTag,labelTag)
}

checkboxGroupInput508 <- function (inputId, choices = "", label=NULL, selected = NULL, inline=FALSE) {
  choices <- choicesWithNames(choices)

  if(!is.null(selected)) selected <- as.character(selected)

  if (is.null(choices) && is.null(choiceNames) && is.null(choiceValues)) {
    choices <- character(0)
  }

  options <- generateOptions508(inputId, choices, selected, inline)

  labelTag <- ""
  if(!is.null(label)) labelTag <- tags$label(label)
  legendTag <- tags$legend(label,class="usa-sr-only")


  tags$fieldset(id=inputId,
                class="usa-fieldset-inputs usa-sans shiny-input-checkboxgroup", ## !important shiny class
                labelTag,
                legendTag,
                tags$ul(class="usa-unstyled-list",options)
  )
}

radioButtons508 <- function(inputId, label, choices, selected = NULL, inline = FALSE, width = NULL,class="") {
  choices <- choicesWithNames(choices)
  selected <- if(is.null(selected)){
    choices[[1]]
  }else {
    as.character(selected)
  }
  if(length(selected) > 1) stop("The 'selected' argument must be of length 1")

  options <- generateOptions508(inputId, choices, selected, inline, type = "radio")
  legendTag <- tags$legend(label,class="em-legend")

  tags$fieldset(
    id=inputId,
    class= paste("usa-fieldset-inputs usa-sans shiny-input-radiogroup",class), ## !important shiny class
    legendTag,
    tags$ul(class="usa-unstyled-list",options)
  )
}

generateOptions508 <- function (inputId, choices, selected, inline=FALSE, type = "checkbox"){
  options <- mapply(
    choices, names(choices),
    FUN = function(value,name) {
      unique_id = paste(inputId,value,sep="-") ## need this in case using same choices across namespaces
      inputTag <- tags$input(id = unique_id, type = type, name = inputId, value = value)
      if(value %in% selected) inputTag$attribs$checked <- "checked"
      labelTag <- tags$label('for'=unique_id, name)
      listTag <- tags$li(inputTag,labelTag)

      if(inline) listTag$attribs$style="display: inline-block; padding-right: 30px;"
      listTag
    }, SIMPLIFY = FALSE, USE.NAMES = FALSE)

  div(class="shiny-options-group",options) ## need shiny-options-group class to replace, not append, new choices
}

downloadButton508 <- function (id, label = "Download"){
  tags$a(id = id, title = "", 'data-original-title' = label,
         tabindex = 0,
         class = 'em-tooltip usa-button download-button',
         tags$span(class = 'usa-sr-only', label))
}

searchBox508 <- function(id, label = "Search") {
  div(class = 'inline',
      div(
        tags$label('for' = 'search', label),
        tags$input(id = id, value = "", class = "form-control", type = 'text')
      ))
}

dropdown508 <- function(inputId,label="",...){
  div(class="dropdown black-text", id = inputId,
      tags$button(type="button",
                  class="usa-accordion-button dropdown-toggle shiny-bound-input arrow-button",
                  'data-toggle'="dropdown",
                  'aria-expanded'="false", label),
      tags$ul(class="dropdown-menu dropdown-menu-form", 'aria-labelledby'=inputId,...)
  )
}

# From Shiny -- re-written in case shiny updated ---------------------------------

firstChoice <- function(choices) {
  if (length(choices) == 0L)
    return()
  choice <- choices[[1]]
  if (is.list(choice))
    firstChoice(choice)
  else choice
}

selectOptions <- function (choices, selected = NULL) {
  html <- mapply(choices, names(choices), FUN = function(choice, label) {
    if (is.list(choice)) {
      sprintf("<optgroup label=\"%s\">\n%s\n</optgroup>",
              htmlEscape(label, TRUE), selectOptions(choice, selected))
    }
    else {
      sprintf("<option value=\"%s\"%s>%s</option>", htmlEscape(choice, TRUE),
              if (choice %in% selected) " selected" else "", htmlEscape(label))
    }
  })
  HTML(paste(html, collapse = "\n"))
}

choicesWithNames <- function (choices) {
  listify <- function(obj) {
    makeNamed <- function(x) {
      if (is.null(names(x)))
        names(x) <- character(length(x))
      x
    }
    res <- lapply(obj, function(val) {
      if (is.list(val))
        listify(val)
      else if (length(val) == 1 && is.null(names(val)))
        as.character(val)
      else makeNamed(as.list(val))
    })
    makeNamed(res)
  }
  choices <- listify(choices)
  if (length(choices) == 0) return(choices)
  choices <- mapply(choices, names(choices), FUN = function(choice, name) {
    if (!is.list(choice))
      return(choice)
    if (name == "")
      stop("All sub-lists in \"choices\" must be named.")
    choicesWithNames(choice)
  }, SIMPLIFY = FALSE)
  missing <- names(choices) == ""
  names(choices)[missing] <- as.character(choices)[missing]
  choices
}
