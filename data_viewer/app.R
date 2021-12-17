library(shiny)
library(dplyr)
library(DBI)
source("plot_data.R")


ui <- fluidPage(
  tags$head(
    # Note the wrapping of the string in HTML()
    tags$style(HTML("
      @import url('https://fonts.googleapis.com/css2?family=Yusei+Magic&display=swap');
      h2 {
        font-family: 'Yusei Magic', sans-serif;
      }
      .avg-val-cards {
        display: flex;
        gap: 1rem;
        justify-content: space-around;
        padding: 0.5rem;
      }
      .avg-val-cards > div {
        border: 1px solid grey;
        padding: 1rem;
        border-radius: 5px;
        font-size: large;
      }
   "))
  ),
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
      div("Average values from last 10 datapoints:",
          div(class = "avg-val-cards",
            div(
                span("CO2", textOutput("avg_co2", container = tags$strong)),
            ),
            div(
                span("Temp", textOutput("avgTemp", container = tags$strong))
            )
          )
      ),
      plotOutput("historyPlot", height = "500px"),
      DT::dataTableOutput("allData")
    )
  )
)

server <- function(input, output) {
  
  air_data <- reactive({
    print("Grabbing data from database")
    input$refresh
    
    con <- dbConnect(RSQLite::SQLite(), "../database/air_quality.db")
    airquality_db <- tbl(con, "air_quality")
    start_time <- as.integer(Sys.time() - as.difftime(input$nHours, unit="hours"))
    air_data <- airquality_db %>% filter(time > start_time)
    
    if (input$useAllData){
      # Remove filter if user requests everything
      air_data <- airquality_db
    }
    
    air_data <- air_data %>% collect() 
    
    if(nrow(air_data) == 0) stop("No observations in time range. Try all-data option.")
    
    air_data <- air_data %>% 
      mutate(
        time = as.POSIXct(time, origin="1970-01-01", tz="EST"),
        temp = (temp * 9 / 5) + 32
      ) %>% 
      rename(
        Time = time, CO2 = co2, Temp = temp, Humidity =  humidity
      ) 
    
    dbDisconnect(con)
    
    air_data
  }) 
  
  recent_obs <- reactive({
    air_data() %>% tail(10)
  })
  
  output$allData <- DT::renderDataTable({
    air_data()
  })
  
  output$historyPlot <- renderPlot({
    plot_air_data(air_data(), "office shed")
  })
  
  output$avg_co2 <- renderText({
    round( mean(recent_obs()$CO2), 2)
  })
  
  output$avgTemp <- renderText({round(mean(recent_obs()$Temp), 2)})
}

# Run the application 
shinyApp(ui = ui, server = server)
