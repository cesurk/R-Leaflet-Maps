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
setwd('C:/Users/cesur/Desktop/StatsCan/R-Leaflet-Maps')


### Shapefile Steps

# 1) Read in CSD-Level Shapefile
# Note: Supporting files (*.dbp, *.prj, *.shp, *.shx) must also be in same directory
shape <- read_sf("shp/lpr_000b16a_e.shp")

# 2) Transform Shapefile to Latitude-and-Longitude and EPSG Projection 4326 
shape_lat_lon <- st_transform(shape, 4326)

# 3) Simply shapefile for quicker mapping
shape_simplified <- rmapshaper::ms_simplify(shape_lat_lon)


### Data Steps

# Import CERB data:
data_in <- read.csv("data/PCU_total_des_candidats_uniques_PT_groupe_age-CERB_total_unique_applicants_PT_Age_group.csv")
data_ref <- read.csv("data/ReferenceData-Age.csv") %>% 
  rename("Group" = "Age.Group.Codes..Codes.de.groupes.d.âge")
pr_concordance <- read.csv("data/province_concordance.csv")

# Clean CERB Data:
#   1) Rename column names 
#   2) Convert Group column to character from numeric for join 
#   3) Join to reference data for full group names
#   4) Keep only required columns
data_clean <- data_in %>%
  rename("Week" = "pcu_date_des_donnees_inclus.cerb_week_ending_date") %>%
  rename("PRCode" = "code_de_la_subdivision_canadienne.canadian_subdivision_code") %>%
  rename("Value" = "compte_unique_du_demandeur.unique_applicant_count") %>%
  rename("Group" = "code_de_groupe_dage.age_group_code") %>%
  mutate("Group" = as.character(Group)) %>%
  left_join(data_ref, by=c("Group"="Group")) %>%
  select(c(Week, PRCode, Age, Value))


# Data aggregation:
#   1) Select only data from week of 2020-10-04
#   2) Sum all age groups together 
data_agg <- data_clean %>%
  filter(Week == "2020-10-04") %>%
  group_by(PRCode) %>% 
  summarise(VALUE = sum(Value))


### Mapping Steps

# Create a continuous palette function based on population domain
pal <- colorNumeric(
  palette = "Blues",
  domain = data_agg$VALUE)


# Join desired data to Shapefile data
shape_and_data <- shape_simplified %>%
  left_join(pr_concordance, by=c('PREABBR'='shape_key')) %>%
  left_join(data_agg, by=c('data_key'='PRCode'))


### Map 1 - CERB Applicants by Province 
leaflet(shape_and_data) %>%
  addPolygons(
    color = "#EEEEEE", weight = 0.3, opacity = 1,
    fillColor = ~pal(VALUE), fillOpacity = 1,
    label = ~paste0(PRNAME, ": ", formatC(VALUE, big.mark = ","))) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addLegend("bottomright", pal = pal, values = ~VALUE,
            title = "Unique CERB Applicants (Week of 2020-10-04)",
            opacity = 1)


### Map 2 - CERB Applicants per thousand people by Province 

# Read in population data
pop_in <- read.csv("data/Province_Population_1710014201.csv")
pop_clean <- pop_in %>%
  rename("REF_DATE" = "ï..REF_DATE") %>%
  rename(POP = "VALUE") %>%
  filter(REF_DATE == 2020) %>%
  select(c(GEO, REF_DATE, POP))

# Join to existing shape and data file
shape_and_data <- shape_and_data %>%
  left_join(pop_clean, by=c('PRENAME'='GEO')) %>%
  mutate(SHARE_PER_K = round((VALUE / POP * 1000), digits=1))

# Create a continuous palette function based on population domain
pal <- colorNumeric(
  palette = "Blues",
  domain = shape_and_data$SHARE_PER_K)

# Map 2 - Map share of applicants
leaflet(shape_and_data) %>%
  addPolygons(
    color = "#EEEEEE", weight = 0.3, opacity = 1,
    fillColor = ~pal(SHARE_PER_K), fillOpacity = 1,
    label = ~paste0(PRNAME, ": ", formatC(SHARE_PER_K, big.mark = ","))) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addLegend("bottomright", pal = pal, values = ~SHARE_PER_K,
            title = "Number of Unique CERB <br/> Applicants / 1,000 People <br/>(Week of 2020-10-04)",
            opacity = 1)

