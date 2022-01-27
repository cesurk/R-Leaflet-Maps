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

# Clean CERB Data:
#   1) Rename column names 
#   2) Convert Group column to character from numeric for join 
#   3) Join to reference data for full group names
#   4) Keep only required columns
data_clean <- data_in %>%
  rename("Week" = "pcu_date_des_donnees_inclus.cerb_week_ending_date") %>%
  rename("PRCode" = "code_de_la_subdivision_canadienne.canadian_subdivision_code") %>%
  rename("Group" = "code_de_groupe_dage.age_group_code") %>%
  mutate("Group" = as.character("Group")) %>%
  rename("Value" = "compte_unique_du_demandeur.unique_applicant_count") %>%
  left_join(data_ref, by=c("Group"="Group")) %>%
  select(c(Week, PRCode, Group, Age))


