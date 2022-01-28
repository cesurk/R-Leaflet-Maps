# Install Required Packages as required
# install.packages(c("shiny", "leaflet", "sf"))

# Read in Required Packages
library(shiny)
library(leaflet)
library(sf)
library(dplyr)
library(rgdal)

# Set Working Directory
# Note: Replace with your desired workspace
setwd('C:/Users/cesur/Desktop/StatsCan/R-Leaflet-Maps')


### Shapefile Steps

# 1) Read in Provincial Shapefile
# Note: Supporting files (*.dbp, *.prj, *.shp, *.shx) must also be in same directory
shape <- read_sf("shp/lpr_000b16a_e.shp")

# 2) Transform Shapefile to Latitude-and-Longitude and EPSG Projection 4326 
shape_lat_lon <- st_transform(shape, 4326)

# 3) Simply shapefile for quicker mapping
shape_simplified <- rmapshaper::ms_simplify(shape_lat_lon)




### Data Steps
# Import Provincial Population data
data_in <- read.csv("data/Province_Population_1710014201.csv")
data_clean <- data_in %>%
  rename("REF_DATE" = "ï..REF_DATE") %>%
  filter(REF_DATE == 2021) %>%
  select(c(GEO, REF_DATE, VALUE))

# Create a continuous palette function based on population domain
pal <- colorNumeric(
  palette = "Blues",
  domain = data_clean$VALUE)



### Map 1 - Very Simple Provincial Map: 
# Plot Shapefile on simple base map 
leaflet(shape_simplified) %>%
  addPolygons(
    color = "#EEEEEE", weight = 0.3, opacity = 1,
    fillColor = "#1572A1", fillOpacity = 0.3)



### Map 2 - Provincial Map of Population:

# Join desired data to Shapefile data
shape_and_data <- left_join(shape_simplified, data_clean, by=c('PRENAME'='GEO'))

# Plot population on provincial polygons
leaflet(shape_and_data) %>%
  addPolygons(
    color = "#EEEEEE", weight = 0.3, opacity = 1,
    fillColor = ~pal(VALUE), fillOpacity = 1,
    label = ~paste0(PRNAME, ": ", formatC(VALUE, big.mark = ","))) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addLegend("bottomright", pal = pal, values = ~VALUE,
            title = "Population (Q4 2021)",
            opacity = 1)



### Map 3 - Provincial Map of Population Using Circles:
# Calculate centroid of each province
centroids <- shape_simplified %>% 
  st_centroid() %>%
  select(c(PRUID, geometry)) %>%
  unnest_wider(geometry) %>%
  rename("cent_long" = "...1", "cent_lati" = "...2")

# Join centroid to shape and data file
shape_and_data <- shape_and_data %>%
  left_join(centroids, by=c('PRUID'='PRUID'))

# Map population data on provincial polygon
leaflet(shape_and_data) %>%
  addPolygons(
    color = "#EEEEEE", weight = 0.3, opacity = 1,
    fillColor = "#EEEEEE", fillOpacity = 1,
    label = ~paste0(PRNAME, ": ", formatC(VALUE, big.mark = ","))) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addCircles(lng = ~cent_long, lat = ~cent_lati, weight = 1,
             radius = ~sqrt(VALUE) * 150, 
             label = ~paste0(PRNAME, ": ", formatC(VALUE, big.mark = ",")))
