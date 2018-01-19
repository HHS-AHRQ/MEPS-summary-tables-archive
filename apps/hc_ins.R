# Ins ----------------------------------------

library(shiny)

addResourcePath('src','../mepstrends/src')
addResourcePath('json','../mepstrends/hc_ins/json')

ui <- htmlTemplate('../mepstrends/hc_ins/index.html')
server <- shinyServer(function(input, output) {})

shinyApp(ui = ui, server = server)