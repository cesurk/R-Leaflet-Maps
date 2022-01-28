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


### Map 1 - Simple Provincial Map: 
# Plot Shapefile on simple base map 
leaflet(shape_simplified) %>%
  addPolygons(
    color = "#EEEEEE", weight = 0.3, opacity = 1,
    fillColor = "#1572A1", fillOpacity = 0.3)


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


### Mapping Steps

# Join desired data to Shapefile data
shape_and_data <- left_join(shape_simplified, data_clean, by=c('PRENAME'='GEO'))


### Map 2 - Provincial Map of Population 
leaflet(shape_and_data) %>%
  addPolygons(
    color = "#EEEEEE", weight = 0.3, opacity = 1,
    fillColor = ~pal(VALUE), fillOpacity = 1,
    label = ~paste0(PRNAME, ": ", formatC(VALUE, big.mark = ","))) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addLegend("bottomright", pal = pal, values = ~VALUE,
            title = "Population (Q4 2021)",
            opacity = 1)

