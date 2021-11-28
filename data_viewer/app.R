library(shiny)
source("plot_data.R")

ui <- fluidPage(
  
  # Application title
  titlePanel("Air Quality Data from W Madison"),
  
  sidebarLayout(
    sidebarPanel(
      actionButton("refresh", "Pull data again")
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
      plotOutput("historyPlot"),
      DT::dataTableOutput("allData")
    )
  )
)

server <- function(input, output) {
  
  air_data <- reactive({
    input$refresh
    r <- GET("http://10.0.0.137:8000/dumpdata") %>% 
      content("text", encoding = "UTF-8")
    
    print("Got data from server/database")
    do.call(rbind, lapply(jsonlite::parse_json(r)$res, data.frame)) %>% 
      as_tibble() %>% 
      mutate(
        time = as.POSIXct(time, origin="1970-01-01"),
        temp = (temp * 9 / 5) + 32
      ) %>% 
      rename(
        Time = time, CO2 = co2,Temp = temp, Humidity =  humidity
      )
  }) 
  
  output$allData <- DT::renderDataTable({
    air_data()
  })
  
  output$historyPlot <- renderPlot({
    plot_air_data(air_data(), "bedroom")
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
