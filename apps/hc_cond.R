# Cond ----------------------------------------

library(shiny)

addResourcePath('src','../mepstrends/src')
addResourcePath('json','../mepstrends/hc_cond/json')

ui <- htmlTemplate('../mepstrends/hc_cond/index.html')
server <- shinyServer(function(input, output) {})

shinyApp(ui = ui, server = server)