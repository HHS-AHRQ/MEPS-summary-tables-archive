# PMED ----------------------------------------

library(shiny)

addResourcePath('src','../mepstrends/src')
addResourcePath('json','../mepstrends/hc_pmed/json')

ui <- htmlTemplate('../mepstrends/hc_pmed/index.html')
server <- shinyServer(function(input, output) {})

shinyApp(ui = ui, server = server)