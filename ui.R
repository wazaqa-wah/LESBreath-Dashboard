library(shinydashboard)
library(shiny)

sideBar <- dashboardSidebar(
  sidebarMenu(id = 'sidebar',
    menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
    div(id = "sidebar_dash",
        conditionalPanel("input.sidebar == 'dashboard'",
          selectInput(inputId = "sensorID",
                      label = "Choose a Sensor",
                      choices = c("LESBreath1"="56213","LESBreath2"="56219",
                                "LESBreath3"="56221","LESBreath4"="56216")
        ))
    ),
    menuItem("Time Machine", tabName = "timeMachine", icon = icon("calendar")),
    div(id = "sidebar_time",
        conditionalPanel("input.sidebar == 'timeMachine'",
          selectInput(inputId = "sensorID",
                      label = "Choose a Sensor",
                      choices = c("LESBreath1"="56213","LESBreath2"="56219",
                                  "LESBreath3"="56221","LESBreath4"="56216")
        ),
          selectInput(
            inputId = "timeSpan",
            label = "Choose a Timeframe",
            choices = c("Day"="daily","Week"="weekly",
                        "Month"="monthly","Year"="yearly")
        )
        )
    ),
    menuItem("About", tabName = "about", icon = icon("info-sign")),
  )
)


body <- dashboardBody(
  tabItems(
    tabItem(tabName = "dashboard",
            h1("Real-time Sensor Data"),
            h2("Sensor 1"),
            fluidRow(
              valueBoxOutput(outputId = "aqiBox"),
              valueBoxOutput(outputId = "pmBox"),
              valueBoxOutput(outputId = "temBox"),
              valueBoxOutput(outputId = "humBox")
            )
    ),
    
    tabItem(tabName = "timeMachine",
            h2("Widgets tab content")
    ),
    tabItem(tabName = "about",
            h2("Widgets tab content")
    )
  )
)

ui <- dashboardPage(
  dashboardHeader(title = "LES Breathe PurpleAir Dashboard"),
  sidebar = sideBar,
  body = body
)

server <- function(input,output) {
  output$sensorID <- renderText(
    {
      input$sensorID
    }
  )
}

shinyApp(ui,server)
