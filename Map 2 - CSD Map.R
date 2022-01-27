# Install Required Packages as required
# install.packages(c("shiny", "leaflet", "sf"))

# Read in Required Packages
library(shiny)
library(leaflet)
library(sf)
library(dplyr)
library(rgdal)
library(tidyr)

# Set Working Directory
# Note: Replace with your desired workspace
setwd('C:/Users/cesur/Desktop/StatsCan/Mapping with Leaflet')


### Shapefile Steps

# 1) Read in CSD-Level Shapefile
# Note: Supporting files (*.dbp, *.prj, *.shp, *.shx) must also be in same directory
shape <- read_sf("shp/lcsd000b16a_e.shp")

# 2) Transform Shapefile to Latitude-and-Longitude and EPSG Projection 4326 
shape_lat_lon <- st_transform(shape, 4326)

# 3) Simply shapefile for quicker mapping
shape_simplified <- rmapshaper::ms_simplify(shape_lat_lon)


### Data Steps

# Import and clean CSD Population data:
#   1) Rename column name to REF_DATE 
#   2) Create new column for CSDUID
#   3) Keep only required columns
data_in <- read.csv("data/CSD_Population_2021_1710014201.csv")
data_clean <- data_in %>%
  rename("REF_DATE" = "ï..REF_DATE") %>%
  mutate(CSDUID = substr(DGUID, nchar(DGUID)-7+1, nchar(DGUID))) %>%
  select(c(CSDUID, REF_DATE, VALUE))

# Data Set 1 - 2021 Population Data:
#   1) Rename column name to REF_DATE 
#   2) Create new column for CSDUID
#   3) Keep only required columns
#   4) Filter for 2021 data
data_2021_population <- data_clean %>%
  filter(REF_DATE == 2021)

# Data Set 2 - Population Percent Change (2020 to 2021):
#   1) Convert data from long to wide
#   2) Calculate percent change
#   3) Filter data for small counts and small absolute change
data_pct_chg <- data_clean %>%
  spread("REF_DATE", "VALUE") %>% 
  mutate("PCT_CHG" = round(((`2021`-`2020`)/`2020`)*100, digits=1)) %>%
  filter((`2021` > 1000) & (`2020` < 1000) | (abs(`2021`-`2020`) > 100))


### Map 3 - Simple CSD-Level Map of population

# Join data to the CSD Shapefile
shape_and_data <- left_join(shape_simplified, data_2021_population, by=c('CSDUID'='CSDUID'))

# Create a color palette function based on domain
pal <- colorNumeric(
  palette = c("#c2d6e9", "#7b177d"),
  domain = data_2021_population$VALUE
)

# Map data
leaflet(shape_and_data) %>%
  addPolygons(
    color = "black", weight = 0.3, opacity = 1,
    fillColor = ~pal(VALUE), fillOpacity = 1,
    label = ~paste0(CSDNAME, ": ", formatC(VALUE, big.mark = ","))) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addLegend("bottomright", pal = pal, values = ~VALUE,
            title = "Population (2021)",
            opacity = 1)




### Map 4 - CSD-Level Map of Population Percent Change in Ontario

# Join data to the CSD Shapefile
shape_and_data <- shape_simplified %>% 
  left_join(data_pct_chg, by=c('CSDUID'='CSDUID')) %>%
  #filter(PRUID == 35)
  # e.g. Ontario = 35, Quebec = 24, British Columbia = 59, ...
  filter(CMANAME == "Montréal")
  # e.g. "Montréal", "Toronto", "Ottawa - Gatineau (Ontario part / partie de l'Ontario)"

# Create a color palette function based on domain, using five bins
pal <- colorNumeric(
  palette = "magma",
    #c("#c2d6e9", "#9eacd4", "#897dbc", "#824aa1", "#7b177d"),
  domain = shape_and_data$PCT_CHG
)

leaflet(shape_and_data) %>%
  addPolygons(
    color = "black", weight = 0.3, opacity = 1,
    fillColor = ~pal(PCT_CHG), fillOpacity = 1,
    label = ~paste0(CSDNAME, ": ", PCT_CHG, "%")) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addLegend("bottomright", pal = pal, values = ~PCT_CHG,
            title = "Percent Change in Population </br>(2020 to 2021)",
            opacity = 1)

