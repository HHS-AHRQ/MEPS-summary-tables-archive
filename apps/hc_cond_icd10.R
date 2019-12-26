# Cond ----------------------------------------

library(shiny)

addResourcePath('src','../mepstrends/src')
addResourcePath('json','../mepstrends/hc_cond_icd10/json')

ui <- htmlTemplate('../mepstrends/hc_cond_icd10/index.html')
server <- shinyServer(function(input, output) {})

shinyApp(ui = ui, server = server)