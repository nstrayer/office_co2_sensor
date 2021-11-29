library(shiny)
library(dplyr)
library(DBI)
source("plot_data.R")

con <- dbConnect(RSQLite::SQLite(), "../database/air_quality.db")
airquality_db <- tbl(con, "air_quality")

ui <- fluidPage(
  titlePanel("Air Quality Data from W Madison"),
  sidebarLayout(
    sidebarPanel(
      actionButton("refresh", "Pull data again"),
      hr(),
      sliderInput("nHours", "Number of hours to pull", min = 1, max = 24, value = 12, step = 1),
      hr(),
      p("Warning, using all data may crash app.", style="color:orangered"),
      checkboxInput("useAllData", "Use all data", FALSE),
    ),
    mainPanel(
      plotOutput("historyPlot", height = "500px"),
      DT::dataTableOutput("allData")
    )
  )
)

server <- function(input, output) {
  
  air_data <- reactive({
    print("Grabbing data from database")
    input$refresh
    
    start_time <- as.integer(Sys.time() - as.difftime(input$nHours, unit="hours"))
    air_data <- airquality_db %>% filter(time > start_time)
    
    if (input$useAllData){
      # Remove filter if user requests everything
      air_data <- airquality_db
    }
    
    air_data <- air_data %>% collect() 
    
    if(nrow(air_data) == 0) stop("No observations in time range. Try all-data option.")
    
    air_data %>% 
      mutate(
        time = as.POSIXct(time, origin="1970-01-01", tz="EST"),
        temp = (temp * 9 / 5) + 32
      ) %>% 
      rename(
        Time = time, CO2 = co2, Temp = temp, Humidity =  humidity
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
