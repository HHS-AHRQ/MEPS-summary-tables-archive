# Care ----------------------------------------

library(shiny)

addResourcePath('src','../mepstrends/src')
addResourcePath('json','../mepstrends/hc_care/json')

ui <- htmlTemplate('../mepstrends/hc_care/index.html')
server <- shinyServer(function(input, output) {})

shinyApp(ui = ui, server = server)