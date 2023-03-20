library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(httr)
library(jsonlite)
library(tidyverse)
library(ggplot2)
library(lubridate)
library(scales)
library(Dict)

#daily is default 10 minutes average
weekly <- "30" #average of 30 minutes
monthly <- "10080" #average of a week
yearly <- "44640" #average of a month
baseUrl <- "https://api.purpleair.com/"
apiKey <- "EEFDC0A9-0138-11ED-8561-42010A800005"



#create function to get data

getParams <- function(timeSpan,pickTime,sensorID){
  currentTime = Sys.time()
  startTime <- Sys.time()-hours(24)
  
  
  timeSpanDict <- Dict$new(
    liveUpdate = Dict$new(
      url =  paste(baseUrl,"v1/groups/1211/members/",
                   sensorID,"/history/csv?start_timestamp=",
                   as.numeric(startTime),"&end_timestamp=",
                   as.numeric(currentTime),"&fields=pm2.5_atm,humidity,temperature", sep = ""),
      breaks = 12,
      .overwrite = TRUE,
      cleanUpFunc = function(data){ 
        return(data %>% 
                 mutate(time=hour(datetime)) %>%
                 group_by(time)
               
        )
      },
      formatFunc = function(x){
        return(x)
      }
    ),
    daily = Dict$new(
      url =  paste(baseUrl,"v1/groups/1211/members/",
                   sensorID,"/history/csv?start_timestamp=", 
                   round(as.numeric(pickTime - 24*3600)) , "&end_timestamp=",
                   round(as.numeric(pickTime)), "&fields=pm2.5_atm,humidity,temperature", sep = ""),
      breaks = 12,
      .overwrite = TRUE,
      cleanUpFunc = function(data){ 
        return(data %>% 
                 mutate(time=hour(datetime)) %>%
                 group_by(time)
               
        )
      },
      formatFunc = function(x){
        return(x)
      }
    ),
    weekly = Dict$new(
      url =  paste(baseUrl,"v1/groups/1211/members/",
                   sensorID,"/history/csv?start_timestamp=", 
                   round(as.numeric(pickTime - 24*3600*7)) , "&end_timestamp=",
                   round(as.numeric(pickTime)), "&fields=pm2.5_atm,humidity,temperature&average=", weekly, sep = ""),
      breaks = 7,
      .overwrite = TRUE,
      cleanUpFunc = function(data){ 
        return(data %>% 
                 mutate(time = round_date(datetime, unit="day")) %>%
                 group_by(time)
        )
      },
      formatFunc = function(x){
        return(date_format(format = "%m-%d")(as.POSIXct(x, origin = "1970-01-01")))
      }
    ),
    monthly = Dict$new(
      url =  paste(baseUrl,"v1/groups/1211/members/",
                   sensorID,"/history/csv?start_timestamp=", 
                   round(as.numeric(pickTime)), "&end_timestamp=",
                   round(as.numeric(pickTime + 24*3600*30)), "&fields=pm2.5_atm,humidity,temperature&average=", monthly, sep = ""),
      .overwrite = TRUE,
      cleanUpFunc = function(data){ 
        return(data %>% 
                 mutate(time = cut.Date(date, breaks = "1 week", labels = FALSE)) %>% 
                 arrange(Order_Date))
      },
      formatFunc = function(x){
        return(date_format(format = "%Y-%m")(as.POSIXct(x, origin = "1970-01-01")))
      }
    ),
    yearly = Dict$new(
      url =  paste(baseUrl,"v1/groups/1211/members/",
                   sensorID,"/history/csv?start_timestamp=", 
                   round(as.numeric(pickTime)) , "&end_timestamp=",
                   round(as.numeric(pickTime + 24*3600*365)), "&fields=pm2.5_atm,humidity,temperature&average=", yearly, sep = ""),
      .overwrite = TRUE,
      cleanUpFunc = function(data){ 
        return(data %>% 
                 mutate(time = year(datetime)) %>%
                 group_by(time))
      },
      formatFunc = function(x){
        return(date_format(format = "%Y-%m")(as.POSIXct(x, origin = "1970-01-01")))
      }
    ),
    .overwrite = TRUE
  )
  
  return(timeSpanDict[timeSpan])
}

getData <- function(v){
  url = v['url']
  #return(url) 
  r = GET(url, add_headers("X-API-Key"=apiKey))
  bin <- content(r,"raw")
  writeBin(bin, "live.csv")
  
  liveData <- read.csv("live.csv",header = TRUE, dec = ",") %>%
    arrange(time_stamp) %>% 
    mutate(humidity = as.numeric(humidity), 
           temperature = as.numeric(temperature),
           pm2.5_outdoor = as.numeric(pm2.5_atm),
           datetime = as_datetime(time_stamp))%>%
    separate(datetime,c("date","time"), sep = " ", remove = FALSE)
    return(liveData)
}


getChart <- function(v, data, chartType){  
    # PM2.5 charts 
    createPMChart <- function(data, cleanUpFunc, formatFunc, breaks) {
      return(cleanUpFunc(data) %>% 
               summarise(quant25 = quantile(pm2.5_outdoor, c(0.25)),
                         quant75 = quantile(pm2.5_outdoor, c(0.75)),
                         mean = mean(pm2.5_outdoor))  %>%
               ggplot() +
               geom_rect(aes(xmin = min(time), xmax = max(time), ymin = 0, ymax=12), fill="#00E40003") +
               geom_rect(aes(xmin = min(time), xmax = max(time), ymin = 12.1, ymax=35.4), fill="#FFFF0003")+
               geom_rect(aes(xmin = min(time), xmax = max(time), ymin = 35.5, ymax=55.4), fill="#FF7E0003")+
               geom_ribbon(aes(x = time, ymin = quant25, ymax=quant75), fill="grey", alpha = 0.6)+
               scale_x_continuous(labels = formatFunc, breaks = scales::pretty_breaks(n = breaks)) + 
               geom_line(aes(x = time, y = mean), color="red")+
               labs(title = "Range of outdoor PM2.5") 
      )
    }
    
    # chart for humidity & temperature
    createChart <- function(data, pickColumn, cleanUpFunc, formatFunc, breaks){
      return(cleanUpFunc(data)) %>% 
               ggplot()+
               scale_x_continuous(labels = formatFunc, breaks = scales::pretty_breaks(n = breaks))+
               geom_line(aes(x=date,y=pickColumn))
    }
    
    if(chartType == 'PM'){
      createPMChart(data,v['cleanUpFunc'], v['formatFunc'], v['breaks'])
    }
    else{
      createChart(data,v['cleanUpFunc'], v['formatFunc'], v['breaks'])
    }
} 


# chart for PM 2.5 

v = getParams("daily",Sys.time(),"56213")
data = getData(v)

getChart(v,data,'PM')


#for ui: define sidebar and body separatly 

sideBar <- dashboardSidebar(
  sidebarMenu(
    menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
    menuItem("Time Machine", tabName = "timeMachine", icon = icon("calendar")),
    menuItem("About", tabName = "about", icon = icon("info-sign"), startExpanded = TRUE),
      selectInput(
        inputId = "sensorID",
        label = "Choose a Sensor",
        choices = c("LESBreath1"="56213","LESBreath2"="56219",
                    "LESBreath3"="56221","LESBreath4"="56216")
      ),
      selectInput(
        inputId = "timeSpan",
        label = "Choose a Timeframe",
        choices = c("Day","Week",
                    "Month","Year")
      ),
  )
)
  

body <- dashboardBody(
  tabItems(
    tabItem(tabName = "dashboard",
            h2("Real-time Sensor Data")
    ),
    
    tabItem(tabName = "timeMachine",
            h2("Widgets tab content")
    ),
    tabItem(tabName = "about",
            h2("Widgets tab content")
    )
  )
)

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
                                   ),
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
  output$chart <- renderPlot({createChart(getData(input$sensorID))})
  output$chart <- renderPlot({createPMChart(getData(input$sensorID))})
  output$sensorID <- renderText({input$sensorID})
  output$pmBox <- renderValueBox({
    valueBox()
  })
}


shinyApp(ui = ui, server = server)



timeSpanDict <- Dict$new(
  liveUpdate = Dict$new(
    url =  paste("&fields=pm2.5_atm,humidity,temperature", sep = ""),
    .overwrite = TRUE
  ))

#test graphics
test30 = get30Data(56213)
test = getData(56213)
ggplot(test, aes(x=time, y=pm2.5_outdoor)) +
  geom_line() +
  geom_hline(yintercept = mean(test$pm2.5_outdoor), color="red") +
  scale_x_continuous(breaks = scales::pretty_breaks(n = 6))

ggplot(test, aes(x=datetime, y=pm2.5_outdoor)) + 
  #scale_x_time(labels=date_format("%H:%M"),breaks = date_breaks("1 hour")) +
  geom_line() + 
  geom_hline(yintercept = mean(test$pm2.5_outdoor), color="red") +
  scale_x_continuous(breaks = scales::pretty_breaks(n = 6))

test_hour <- test %>% mutate(hour = hour(datetime))%>%  
  group_by(hour) %>% 
  summarise(quant25 = quantile(pm2.5_outdoor, c(0.25)),
            quant75 = quantile(pm2.5_outdoor, c(0.75)),
            mean = mean(pm2.5_outdoor))

ggplot(test_hour) +
  geom_rect(aes(xmin = 0, xmax = 24, ymin = 0, ymax=12), fill="#00E40003") +
  geom_rect(aes(xmin = 0, xmax = 24, ymin = 12.1, ymax=35.4), fill="#FFFF0003")+
  geom_rect(aes(xmin = 0, xmax = 24, ymin = 35.5, ymax=55.4), fill="#FF7E0003")+
  geom_ribbon(aes(x = hour, ymin = quant25, ymax=quant75), fill="grey", alpha = 0.6)+
  scale_x_continuous(breaks = scales::pretty_breaks(n = 12)) + 
  geom_line(aes(x = hour, y = mean), color="red")+
  labs(title = "Range of outdoor PM2.5")

ggplot(test30, aes(x=datetime, y=pm2.5_outdoor)) +
  geom_line() +
  geom_hline(yintercept = mean(test$pm2.5_outdoor), color="red")

i <- seq(as.Date("2022/07/11"), as.Date("2022/07/17"),"days")




test_week_hour <- test30 %>% 
  group_by(date) %>%
  summarise(quant25 = quantile(pm2.5_outdoor, c(0.25)),
            quant75 = quantile(pm2.5_outdoor, c(0.75)),
            mean = mean(pm2.5_outdoor))
  
ggplot(test_week_hour) +
  geom_rect(aes(xmin = 1, xmax = 7, ymin = 0, ymax=12), fill="#00E40003") +
  geom_rect(aes(xmin = 1, xmax = 7, ymin = 12.1, ymax=35.4), fill="#FFFF0003")+
  geom_rect(aes(xmin = 1, xmax = 7, ymin = 35.5, ymax=55.4), fill="#FF7E0003")+
  geom_ribbon(aes(x = as.numeric(as.factor(date)), ymin = quant25, ymax=quant75), fill="grey", alpha = 0.6)+
  geom_line(aes(x = as.numeric(as.factor(date)), y = mean), color="red")+
  labs(title = "Range of outdoor PM2.5") 


