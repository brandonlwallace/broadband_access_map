#Interactive Map for Computer Access & Broadband Connectivity for Labor Force Participation

library(shiny) 
library(shinythemes)
library(leaflet)
library(leaflet.extras)
library(sf)
library(shinyjs)
library(dplyr)
library(tidycensus)
library(sf)
library(tigris)
library(tidyverse)
library(viridis)
library(plotly)
library(DT)

#Connecting key to Census API
#census_api_key(jsonlite::fromJSON(".creds.json"), install = TRUE)

#Setting all variables for API pull to create a datatable
data_vars = c(total_population = "B01001_001", 
              total_pop_employed = "B28007_003", 
              total_pop_unemployed = "B28007_009", 
              total_pop_employed_has_computer = "B28007_004", 
              total_pop_employed_has_cpu_and_dailup = "B28007_005", 
              total_pop_employed_has_cpu_and_broadband = "B28007_006",
              total_pop_employed_no_computer = "B28007_008",
              total_pop_unemployed_no_computer = "B28007_014")

#Transforming API pull into into a data frame and breaking the long data into wide data based on county in the United States
broadband_data <- get_acs(geography = "county", variables = data_vars, year = 2021, geometry = TRUE)
broadband_df <- as.data.frame(broadband_data)[,c(1:4)] %>% spread(variable, estimate) 

#Creating a data pull for the first polygon option
visual_has_broadband <- get_acs(geography = "county", variables = c(total_pop_employed_has_cpu_and_broadband = "B28007_006"),
                                summary_var = c(employed_population = "B28007_001"),
                                year = 2021, geometry = TRUE) %>% mutate(proportion = (estimate/summary_est) *100) %>%
                        st_transform(crs = "+init=epsg:4326")
#the variable (population of workers with a computer and broadband access) is divided by the summary variable (population in the labor force) so that the user can compare relative across counties.

#Creating a data pull for the second polygon option
visual_no_computer <- get_acs(geography = "county", variables = c(total_pop_unemployed_no_computer = "B28007_014"), 
                              summary_var = c(employed_population = "B28007_001"), 
                              year = 2021, geometry = TRUE) %>% mutate(proportion = (estimate/summary_est) * 100) %>%
                      st_transform(crs = "+init=epsg:4326") 

#Creating a data pull for the third polygon option
working_but_no_computer <- get_acs(geography = "county", variables = c(total_pop_employed_no_computer = "B28007_008"),
                                   summary_var = c(employed_population = "B28007_001"), 
                                   year = 2021, geometry = TRUE) %>% mutate(proportion = (estimate/summary_est) * 100) %>%
                      st_transform(crs = "+init=epsg:4326") 

#Setting the fill palettes for each polygon option
pal_visual_has_broadband <- colorNumeric(palette = "magma", domain = visual_has_broadband$proportion)
pal_visual_no_computer <- colorNumeric(palette = "inferno", domain = visual_no_computer$proportion) 
pal_working_but_no_computer <- colorNumeric(palette = "inferno", domain = working_but_no_computer$proportion) 



# Defined UI for app
ui <- fluidPage(
  theme = shinytheme("united"),
        titlePanel("Computer and Broadband Access for the Labor Force"), 
          sidebarLayout(
            sidebarPanel(
            #Allowing the user to see only one map at a time with radio buttons
                radioButtons(inputId = "map_display",
                             label = "Map Layer Options:",
                             choices = c("Employeed Population with Broadband and a Personal Computer" = "visual_has_broadband", 
                                         "Unemployed Population without a Computer" = "visual_no_computer", 
                                         "Employed Population without a Computer" = "working_but_no_computer"),
                             selected = c("Employeed Population with Broadband and a Personal Computer" = "visual_has_broadband")),
                #Creating a filter option for both charts
                sliderInput(inputId = "n_counties",
                            label = "Number of Counties Shown in Bar Chart:",
                            min = 5, 
                            max = 50,
                            value = 25),
                sliderInput(inputId = "n_counties2",
                            label = "Number of Counties Shown in Scatter Plot:",
                            min = 100, 
                            max = 1500,
                            value = 1000),
                downloadButton("downloadData", 
                               label ="Export Data on Computer and Broadband Access",
                               icon = shiny::icon("download"))),
             mainPanel(
               tabsetPanel(
                 tabPanel("Map",
                          # Using Shiny JS
                          shinyjs::useShinyjs(), #changing how big the map appears on screen
                          tags$style(type = "text/css", ".leaflet {height: calc(100vh - 90px) !important;}"),
                          leafletOutput("map")),
                 tabPanel("Datatable", DTOutput("table")),
                 tabPanel("Bar Chart", plotlyOutput("bar_graph")),
                 tabPanel("Scatter Plot", plotlyOutput("scatter_graph"))
                   )
                  ),
            position = "left", fluid = TRUE)
          )

# Define server logic for map and data exploration pages
server <- function(input, output) {

  #Setting up the plain map without any polygons
  output$map <- renderLeaflet({
    leaflet() %>%
      addProviderTiles(provider = "CartoDB.Positron") %>%
      setView(-79.995888, 40.440624, zoom = 8)
  })
  
  #Update the Polygons and Legend depending on which radio button is selected using "input$map_display"
  observe({ 
    if (input$map_display == "visual_has_broadband") {
      leafletProxy("map") %>% 
        clearGroup("polys") %>% 
        clearControls()  %>%
        addPolygons(data = visual_has_broadband,
                    popup = ~ str_extract(NAME, "^([^,]*)"),
                    stroke = FALSE,
                    smoothFactor = 0,
                    fillOpacity = 0.5,
                    color = ~pal_visual_has_broadband(proportion)) %>%
        addLegend("bottomright", 
                  pal = pal_visual_has_broadband, 
                  values = visual_has_broadband$proportion,
                  title = "Percentage of Labor Market in County",
                  opacity = 1)
    } else if (input$map_display == "visual_no_computer") {
      leafletProxy("map") %>% 
        clearGroup("polys") %>% 
        clearControls()  %>%
        addPolygons(data = visual_no_computer,
                    popup = ~ str_extract(NAME, "^([^,]*)"),
                    stroke = FALSE,
                    smoothFactor = 0,
                    fillOpacity = 0.5, 
                    color = ~pal_visual_no_computer(proportion)) %>%
        addLegend("bottomright", 
                  pal = pal_visual_no_computer, 
                  values = visual_no_computer$proportion,
                  title = "Percentage of Labor Market in County",
                  opacity = 1)
    } else {
      leafletProxy("map") %>% 
        clearGroup("polys") %>%
        clearControls() %>%
        addPolygons(data = working_but_no_computer,
                    popup = ~ str_extract(NAME, "^([^,]*)"),
                    stroke = FALSE,
                    smoothFactor = 0,
                    fillOpacity = 0.5,
                    color = ~pal_working_but_no_computer(proportion)) %>%
        addLegend("bottomright", 
                  pal = pal_working_but_no_computer, 
                  values = working_but_no_computer$proportion,
                  title = "Percentage of Labor Market in County",
                  opacity = 1)
    }
  })  

  #Render function for simple data table
  output$table <- renderDT({
    datatable(broadband_df, class = 'cell-border stripe') 
  })
  
  #filtering dataset based on input
  worst_internet <- reactive({
    broadband_df[order(broadband_df$total_pop_employed_has_cpu_and_dailup, decreasing = TRUE), ] %>% 
      top_n(input$n_counties, total_pop_employed_has_cpu_and_dailup)
  })
  
  #Interactive chart showing total the counties with the most dial-up connections. Using can view the largest 5 to 50 counties depending on n_counties
  output$bar_graph<-renderPlotly({
    plot_ly(data = worst_internet(), x = ~NAME, y = ~total_pop_employed_has_cpu_and_dailup, type = "bar") %>% 
      layout(title = 'Counties with the Most Dial-up Connections', 
             xaxis = list(title = '', visible = FALSE), 
             yaxis = list(title = 'Total Workers with Dial-up'))
  })
  
  #Filtering dataset based on input
  worst_unemployment <- reactive({
    broadband_df[order(broadband_df$total_pop_unemployed, decreasing = TRUE), ] %>% 
      top_n(input$n_counties2, total_pop_unemployed_no_computer)
  })
  
  #Interactive chart showing the total number of unemployed people vs those unemployed without access to a computer. The user can view the top 100 to 1500 counties by unemployed people without computers
  output$scatter_graph<-renderPlotly({
    plot_ly(data = worst_unemployment(), x = ~total_pop_unemployed_no_computer, y =~total_pop_unemployed, text = ~NAME, size = ~total_pop_employed) %>% 
      layout(title = 'Counties with the Largest Unemployed Population without a Computer', 
             xaxis = list(title = 'Number of Unemployed Individuals without a Computer'), 
             yaxis = list(title = 'Total Unemployed Individuals'))  
  })
  
  # The download button allows the user to download the dataset on broadband connectivity
  output$downloadData <- downloadHandler(
    filename = function() {
      paste("data-",Sys.Date(), ".csv", sep="")
    },
    content = function(file) {
      write.csv(broadband_df, file)
    }
  )
  
}

# Run the application 
shinyApp(ui = ui, server = server) 
