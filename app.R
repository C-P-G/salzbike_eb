Sys.setlocale("LC_ALL", "en_US.UTF-8")

# load libraries ---------------------------------------------------------
library(shiny)
library(leaflet)
library(sf)
library(dplyr)
library(lwgeom)
library(httr)
library(ggplot2)
library(htmltools)
library(shinythemes)
library(thematic)
library(RColorBrewer)

# load data ---------------------------------------------------------------
#setwd("C:/Users/clair/Desktop/ubuntu_salzbike/data")

trips_bikers <- read.csv("data/Totaltrips_Bikers_studyarea.csv")
trips_hikers <- read.csv("data/Totaltrips_Hikers_studyarea.csv")
km <- read.csv2("data/km_studyarea.csv")

trips_bikers <- rename(trips_bikers, total_bikers = total_trips)
trips_hikers <- rename(trips_hikers, total_hikers = total_trips)

trips_bikers <- rename(trips_bikers, edgeUID = edgeuid)
trips_hikers <- rename(trips_hikers, edgeUID = edgeuid)

hours_bikers <- read.csv("data/Hourlystats_bikers_studyarea.csv") 
hours_bikers$hour <- as.factor(hours_bikers$hour)
hours_hikers <- read.csv("data/Hourlystats_hikers_studyarea.csv") 

weekdays_bikers <- read.csv("data/Weekdaystats_bikers_studyarea.csv") 
weekdays_hikers <- read.csv("data/Weekdaystats_hikers_studyarea.csv") 

months_bikers <- read.csv("data/Monthlystats_bikers_studyarea.csv") 
months_hikers <- read.csv("data/Monthlystats_hikers_studyarea.csv")
# Define the order of the levels
weekday_levels <- c("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
month_levels <- c("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December")

# Convert 'weekday' into an ordered factor
weekdays_bikers$weekday <- factor(weekdays_bikers$weekday, levels = weekday_levels, ordered = TRUE)
weekdays_hikers$weekday <- factor(weekdays_hikers$weekday, levels = weekday_levels, ordered = TRUE)

# Convert 'month' into an ordered factor
months_bikers$month <- factor(months_bikers$month, levels = month_levels, ordered = TRUE)
months_hikers$month <- factor(months_hikers$month, levels = month_levels, ordered = TRUE)

# 1.1 generate overall distribution plots -----------------------------------------
# Plot for overall distribution of hours for bikers
plot_hour_bikers <- ggplot(hours_bikers, aes(x = hour)) +
  geom_bar(stat = "count") +
  ggtitle("Overall Distribution of Hours for Bikers")

# Plot for overall distribution of hours for hikers
plot_hour_hikers <- ggplot(hours_hikers, aes(x = hour)) +
  geom_bar(stat = "count") +
  ggtitle("Overall Distribution of Hours for Hikers")

# Plot for overall distribution of weekdays for bikers
plot_weekday_bikers <- ggplot(weekdays_bikers, aes(x = weekday)) +
  geom_bar(stat = "count") +
  ggtitle("Overall Distribution of Weekdays for Bikers")

# Plot for overall distribution of weekdays for hikers
plot_weekday_hikers <- ggplot(weekdays_hikers, aes(x = weekday)) +
  geom_bar(stat = "count") +
  ggtitle("Overall Distribution of Weekdays for Hikers")

# Plot for overall distribution of months for bikers
plot_month_bikers <- ggplot(months_bikers, aes(x = month)) +
  geom_bar(stat = "count") +
  ggtitle("Overall Distribution of Months for Bikers")

# Plot for overall distribution of months for hikers
plot_month_hikers <- ggplot(months_hikers, aes(x = month)) +
  geom_bar(stat = "count") +
  ggtitle("Overall Distribution of Months for Hikers")

# 1.2 WFS request --------------------------------------------------------------------
# Create the WFS request URL
# Define the URL and layer name
wfs_url <- "https://sdiservices.zgis.at/geoserver/salzbike/ows"
layer_name <- "salzbike:FilteredWegenetz_studyarea"
#define output format of wfs request
output_format <- "application/json"

# for testing set max features to 200 
# for deploying set to 60000? check again 
wfs_request <- paste0(wfs_url, "?service=WFS&version=1.0.0&request=GetFeature&typeName=", layer_name, "&maxFeatures=20000&outputFormat=", output_format)

# Function to retrieve WFS data and convert to sf object
getWFSData <- function() {
  # Fetch the WFS data as GeoJSON
  wfs_response <- GET(wfs_request)
  wfs_geojson <- content(wfs_response, "text")
  
  # Convert the GeoJSON to an sf object
  wfs_data <- st_read(wfs_geojson)
  wfs_data$geometry <- st_zm(wfs_data$geometry)
  # add kilometer column 
  wfs_data <- left_join(wfs_data, km, by = "edgeUID")
  
  return(wfs_data)
}

# UI ---------------------------------------------------------------------------------
ui <- fluidPage(theme = shinytheme("slate"),
                tags$head(
                  tags$style(HTML("
                    body, html {
                      height: 100vh;
                      margin: 0;
                      padding: 0;
                      overflow: hidden;
                    }
                    .shiny-output-area {
                      height: 100%;
                    }
                  "))
                ),
                mainPanel(
                  leafletOutput("map", width = "100%", height = "100vh")
                ),
                div(style = "padding: 10px;", 
                    absolutePanel(top = 10, 
                                  right = 0, 
                                  style = "z-index:500;",
                                  textOutput("clicked_segment"),
                                  fluidRow(
                                    column(6, 
                                           checkboxInput("km_checkbox", 
                                                         "Filter for the top km",
                                                         value = FALSE)),
                                    column(6, 
                                           checkboxInput("steepness_checkbox", 
                                                         "Filter for trail steepness",
                                                         value = FALSE)),
                                    column(6, 
                                           sliderInput("km_filter",
                                                       "Filter by Kilometer",
                                                       min = 0, max = 100, value = c(0, 500),
                                                       step = 5))
                                  ),
                                  fluidRow(
                                    column(6, plotOutput("hour_plot_bikers", height = "200")),
                                    column(6, plotOutput("hour_plot_hikers", height = "200"))
                                  ),
                                  fluidRow(
                                    column(6, plotOutput("weekday_plot_bikers", height = "200px")),
                                    column(6, plotOutput("weekday_plot_hikers", height = "200px"))
                                  ),
                                  fluidRow(
                                    column(6, plotOutput("month_plot_bikers", height = "200px")),
                                    column(6, plotOutput("month_plot_hikers", height = "200px"))
                                  )
                    )
                )
)

# ... (remaining code)

# ... (remaining code)






# Server logic -----------------------------------------------------------------
server <- function(input, output, session) {
  thematic_shiny()
  
  
  
  wfs_data <- reactive(getWFSData())
  
  # Join trips_bikers with wfs_data based on edgeuid or edgeUID
  joined_bikers <- reactive({
    print("Inside joined_bikers")
    left_join(wfs_data(), trips_bikers, by = "edgeUID")
  })
  
  # Join trips_hikers with wfs_data based on edgeuid or edgeUID
  joined_hikers <- reactive({
    print("Inside joined_hikers")
    left_join(wfs_data(), trips_hikers, by = "edgeUID")
  })
  
  # Check if 'total_trips' column exists in joined_data
  total_bikers_exist <- reactive({
    "total_bikers" %in% names(joined_bikers())
  })
  total_hikers_exist <- reactive({
    "total_hikers" %in% names(joined_hikers())
  })
  # color function -------------------------------------------------------
  # Define a custom color palette based on total_trips column
  color_bike <- reactive({
    if (total_bikers_exist()) {
      print("join bikers successful")
      # Customizing the color palette
      bluepalette <- colorRampPalette(c("lightblue", "darkblue"))(n = 20)
      
      # Generating the colorNumeric function with the modified palette
      colorNumeric(
        palette = bluepalette,
        domain = joined_bikers()$total_bikers,
        na.color = "transparent"
      )
      
    }
  })
  
  color_hike <- reactive({
    if (total_hikers_exist()) {
      print("join hikers successful")
      
      redpalette <- colorRampPalette(c("#FFC0CB", "#8B0000"))(n = 20)
      
      # Generating the colorNumeric function with the modified palette
      colorNumeric(
        palette = redpalette,
        domain = joined_hikers()$total_hikers,
        na.color = "transparent"
      )
    }
  })
  
  output$map <- renderLeaflet({
    leaflet() %>%
      addProviderTiles("CartoDB.DarkMatter", group = "Carto dark") %>%
      addProviderTiles("CartoDB.Positron", group = "Carto light") %>%
      addTiles(group = "OSM standard") %>%
      setView(lng = 13.055, lat = 47.8095, zoom = 10) %>%
      addCircleMarkers(
        data = st_coordinates(st_startpoint(wfs_data()$geometry)),
        clusterOptions = markerClusterOptions(), group = "strava" 
      ) %>% 
      addLayersControl(baseGroups = c("OSM standard", "Carto dark", "Carto light"),
                       overlayGroups = c("strava", "hikers", "bikers"),
                       options = layersControlOptions(collapsed = FALSE,
                                                      defaultBase = "Carto dark"))
  })
  
  observeEvent(input$map_zoom, {
    zoom <- input$map_zoom
    leafletProxy("map") %>%
      clearMarkers()
    
    if (zoom >= 12) {
      leafletProxy("map") %>%
        clearShapes() %>%
        clearMarkers() %>% 
        clearMarkerClusters() %>% 
        addPolylines(group = "bikers",
                     data = joined_bikers(),
                     color = if (total_bikers_exist()) { ~color_bike()(total_bikers)},
                     opacity = 0.6,
                     layerId = ~edgeUID,
                     popup = ~paste("Edgeuid: ", as.character(edgeUID), "<br>",
                                    "Gesamtanzahl Radfahrten", as.character(total_bikers), "<br>",
                                    "Segment Laenge (in km):", as.character(km)),
                     highlightOptions = highlightOptions(color = "yellow",
                                                         weight = 6)
        ) %>% 
        addPolylines(group = "hikers",
                     data = joined_hikers(),
                     color = if (total_hikers_exist()) { ~color_hike()(total_hikers)},
                     opacity = 0.6,
                     layerId = ~edgeUID,
                     popup = ~paste("Edgeuid: ", as.character(edgeUID), "<br>",
                                    "Gesamtanzahl Wanderungen:", as.character(total_hikers), "<br>",
                                    "Segment Laenge (in km):", as.character(km)),
                     highlightOptions = highlightOptions(color = "yellow",
                                                         weight = 6))
      
    } else if (zoom <= 11) {
      leafletProxy("map") %>%
        clearShapes() %>%
        addCircleMarkers(
          data = st_coordinates(st_startpoint(wfs_data()$geometry)),
          clusterOptions = markerClusterOptions(), group = "strava"
        )
    }
  })
  
  # Click Event: add plots -----------------------------------
  click_status <- reactiveVal(0)
  
  # Modify your observeEvent for input$map_shape_click
  observeEvent(input$map_shape_click, {
    if (is.null(input$map_shape_click$id)) {
      click_status(0)  # no valid shape clicked
      print("no segment here")
    } else {
      click_status(1)  # valid shape clicked
      click_id <- input$map_shape_click$id
      print(click_id)
      updateTextInput(session, "clicked_marker", value = click_id)
    }
  })
  # test edgeuid info 
  output$clicked_segment <- renderText({
    req(input$map_shape_click)
    paste("Ausgewaehltes Segment edgeUID: ", input$map_shape_click$id)
  })
  
  # Filter dataframes for distribution of edgeuid 
  # Filter dataframes for distribution of edgeuid 
  selected_hour_bikers <- reactive({
    req(input$map_shape_click)
    selected_data <- filter(hours_bikers, edgeuid == as.integer(input$map_shape_click$id))
    print(selected_data)
    selected_data
  })
  selected_hour_hikers <- reactive({
    req(input$map_shape_click)
    selected_data <- filter(hours_hikers, edgeuid == as.integer(input$map_shape_click$id))
    print(selected_data)
    selected_data
  })
  selected_weekday_bikers <- reactive({
    req(input$map_shape_click)
    selected_data <- filter(weekdays_bikers, edgeuid == as.integer(input$map_shape_click$id))
    print(selected_data)
    selected_data
  })
  
  selected_weekday_hikers <- reactive({
    req(input$map_shape_click)
    selected_data <- filter(weekdays_hikers, edgeuid == as.integer(input$map_shape_click$id))
    print(selected_data)
    selected_data
  })
  selected_month_bikers <- reactive({
    req(input$map_shape_click)
    selected_data <- filter(months_bikers, edgeuid == as.integer(input$map_shape_click$id))
    print(selected_data)
    selected_data
  })
  selected_month_hikers <- reactive({
    req(input$map_shape_click)
    selected_data <- filter(months_hikers, edgeuid == as.integer(input$map_shape_click$id))
    print(selected_data)
    selected_data
  })
  
  
  output$hour_plot_bikers <- renderPlot({
    if (click_status() == 0) {
      print("Render overall hour plot for bikers")
      plot_hour_bikers
    } else {
      req(selected_hour_bikers())
      # Render the plot for the selected edgeuid
      ggplot(selected_hour_bikers(), aes(x = hour, y = total_trips)) +
        geom_bar(stat = "identity") +
        ggtitle("Biker Hour Plot")
    }
  }, height = 200, width = 200)
  
  output$hour_plot_hikers <- renderPlot({
    if (is.null(input$map_shape_click)) {
      print("Render overall hour plot for bikers")
      plot_hour_hikers
      # ggplot(overall_hour_bikers, ...)
    } else {
      req(selected_hour_hikers())
      # Render the plot for the selected edgeuid
      ggplot(selected_hour_hikers(), aes(x = hour, y = total_trips)) +
        geom_bar(stat = "identity") +
        ggtitle("Hiker Hour Plot")
    }
  }, height = 200, width = 200)
  
  output$weekday_plot_bikers <- renderPlot({
    if (is.null(input$map_shape_click)) {
      print("Render overall weekday plot for bikers")
      plot_weekday_bikers
      # ggplot(overall_hour_bikers, ...)
    } else {
      req(selected_weekday_bikers())
      # Render the plot for the selected edgeuid
      ggplot(selected_weekday_bikers(), aes(x = weekday, y = total_trips)) +
        geom_bar(stat = "identity") +
        ggtitle("Biker Weekday Plot")
    }
  }, height = 200, width = 200)
  
  output$weekday_plot_hikers <- renderPlot({
    if (is.null(input$map_shape_click)) {
      print("Render overall weekday plot for hikers")
      plot_weekday_hikers
      # ggplot(overall_hour_bikers, ...)
    } else {
      req(selected_weekday_hikers())
      # Render the plot for the selected edgeuid
      ggplot(selected_weekday_hikers(), aes(x = weekday, y = total_trips)) +
        geom_bar(stat = "identity") +
        ggtitle("Hiker Weekday Plot")
    }
  }, height = 200, width = 200)
  
  output$month_plot_bikers <- renderPlot({
    if (is.null(input$map_shape_click)) {
      print("Render overall month plot for bikers")
      plot_month_bikers
      # ggplot(overall_hour_bikers, ...)
    } else {
      req(selected_month_bikers())
      # Render the plot for the selected edgeuid
      ggplot(selected_month_bikers(), aes(x = month, y = total_trips)) +
        geom_bar(stat = "identity") +
        ggtitle("Biker Month Plot")
    }
  }, height = 200, width = 200)
  
  output$month_plot_hikers <- renderPlot({
    if (is.null(input$map_shape_click)) {
      print("Render overall month plot for hikers")
      plot_month_hikers
      # ggplot(overall_hour_bikers, ...)
    } else {
      req(selected_month_hikers())
      # Render the plot for the selected edgeuid
      ggplot(selected_month_hikers(), aes(x = month, y = total_trips)) +
        geom_bar(stat = "identity") +
        ggtitle("Hiker Month Plot")
    }
  }, height = 200, width = 200)
  
  # -----------------------------------------------------------------------------
  # km filter function 
  filtered_polylines <- reactive({
    if (input$km_checkbox) {
      total_km <- sum(km$km)
      km_filter <- input$km_filter
      
      if (km_filter[2] >= total_km) {
        return(joined_bikers())
      }
      
      filtered_bikers <- joined_bikers() %>%
        arrange(desc(total_bikers)) %>%
        mutate(cumulative_km = cumsum(km))
      
      filtered_hikers <- joined_hikers() %>%
        arrange(desc(total_hikers)) %>%
        mutate(cumulative_km = cumsum(km))
      
      filtered_bikers <- filtered_bikers %>%
        filter(cumulative_km <= km_filter[2])
      
      filtered_hikers <- filtered_hikers %>%
        filter(cumulative_km <= km_filter[2])
      
      return(list(bikers = filtered_bikers, hikers = filtered_hikers))
    } else {
      return(list(bikers = joined_bikers(), hikers = joined_hikers()))
    }
  })
  
  observe({
    if (input$km_checkbox) {
      leafletProxy("map") %>%
        clearShapes() %>%
        clearMarkers() %>%
        clearMarkerClusters() %>%
        addPolylines(group = "bikers",
                     data = filtered_polylines()$bikers,
                     color = if (total_bikers_exist()) { ~color_bike()(total_bikers) },
                     opacity = 0.8,
                     layerId = ~edgeUID,
                     popup = ~paste("Edgeuid: ", as.character(edgeUID), "<br>",
                                    "Gesamtanzahl Radfahrten", as.character(total_bikers), "<br>",
                                    "Segment Laenge (in km):", as.character(km)),
                     highlightOptions = highlightOptions(color = "yellow",
                                                         weight = 6)
        ) %>%
        addPolylines(group = "hikers",
                     data = filtered_polylines()$hikers,
                     color = if (total_hikers_exist()) { ~color_hike()(total_hikers) },
                     opacity = 0.8,
                     layerId = ~edgeUID,
                     popup = ~paste("Edgeuid: ", as.character(edgeUID), "<br>",
                                    "Gesamtanzahl Wanderungen:", as.character(total_hikers), "<br>",
                                    "Segment Laenge (in km):", as.character(km)),
                     highlightOptions = highlightOptions(color = "yellow",
                                                         weight = 6)
        )
    } else {
      leafletProxy("map") %>%
        clearShapes() %>%
        clearMarkerClusters() %>%
        addCircleMarkers(
          data = st_coordinates(st_startpoint(wfs_data()$geometry)),
          clusterOptions = markerClusterOptions(), group = "strava"
        )
    }
  })
  observeEvent(input$map_shape_click, {
    clicked_id <- input$map_shape_click$id
    print(clicked_id)
  })
  
}

# Run the Shiny app
shinyApp(ui, server)
