# Use ----------------------------------------

library(shiny)

addResourcePath('src','../mepstrends/src')
addResourcePath('json','../mepstrends/hc_use/json')

ui <- htmlTemplate('../mepstrends/hc_use/index.html')
server <- shinyServer(function(input, output) {})

shinyApp(ui = ui, server = server)
