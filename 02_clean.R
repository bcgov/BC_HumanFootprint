# Copyright 2021 Province of British Columbia
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

#Roads - clean and split into low, medium, high use
#If roads raster is already made then skip this section
roads_file <- file.path(spatialOutDir,"roadsSR.tif")
if (!file.exists(roads_file)) {
  #Check the types
unique(roads_sf_in$ROAD_CLASS)
unique(roads_sf_in$ROAD_SURFACE)

#Eliminate non-roads
notRoadsCls <- c("ferry", "water", "proposed")
notRoadsSurf<-c("boat")

roads_sf_1<-roads_sf_in %>%
  filter(!ROAD_CLASS %in% notRoadsCls,
         !ROAD_SURFACE %in% notRoadsSurf)

HighUseCls<-c("arterial","highway", "ramp","freeway")
ModUseCls<-c("local","collector","arterial" ,"recreation","alleyway","restricted",
             "service","resource","driveway","strata","unclassified")
LowUseCls<-c("lane","skid","trail","pedestrian","passenger")

HighUseSurf<-c("paved")
ModUseSurf<-c("loose","unknown","seasonal","rough")
LowUseSurf<-c("overgrown","decommissioned")

#Add new attribute that holds the use classification
roads_sf <- roads_sf_1 %>%
  mutate(RoadUse = case_when((ROAD_CLASS %in% HighUseCls & ROAD_SURFACE %in% HighUseSurf) ~ 1, #high use
                            (ROAD_CLASS %in% LowUseCls | ROAD_SURFACE %in% LowUseSurf) ~ 3,#low use
                             TRUE ~ 2)) # all the rest are medium use

#Check the assignment
Rd_Tbl <- st_set_geometry(roads_sf, NULL) %>%
  count(ROAD_SURFACE, ROAD_CLASS, RoadUse)

nrow(roads_sf)-nrow(roads_sf_1)

# Save as RDS for quicker access later.
saveRDS(roads_sf, file = "tmp/DRA_roads_sf_clean.rds")
# Also save as geopackage format for use in GIS
write_sf(roads_sf, "out/data/roads_clean.gpkg")

#Use Stars to rasterize according to RoadUse and save as a tif
#first st_rasterize needs a template to 'burn' the lines onto
template = BCr_S
template[[1]][] = NA
roadsSR<-st_rasterize(roads_sf[,"RoadUse"], template)
write_stars(roadsSR,dsn=file.path(spatialOutDir,'roadsSR.tif'))
} else {
  #Read in raster roads with values 0-none, 1-high use, 2-moderate use, 3-low use)
  roadsR<-raster(file.path(spatialOutDir,'roadsSR.tif'))
}

#Assign road weights for example: H-400, m-100, l-3 - based on values in the disturbance.xlsx spreadsheet
LinearDisturbance_LUT<-data.frame(read_excel(file.path(dataOutDir,paste('disturbance.xlsx',sep='')),sheet='LinearDisturbance')) %>%
  dplyr::select(ID,Resistance,SourceWt)

#By AOI
roadsR_AOI<-roadsR %>%
  mask(AOI) %>%
  crop(AOI)
#roads_LUT<-data.frame(rdCode=c(1,2,3),weights=c(400,100,3))
roads_W<-subs(roadsR_AOI, LinearDisturbance_LUT, by='ID',which='Resistance')

#By Prov
roads_WP<-subs(roadsR, LinearDisturbance_LUT, by='ID',which='Resistance')

##############
#Disturbance  Layer
#Assign weights to layer - based on values in spreadsheet built off raster's legend
AreaDisturbance_LUT<-data.frame(read_excel(file.path(dataOutDir,paste('disturbance.xlsx',sep='')),sheet='AreaDisturbance')) %>%
  dplyr::select(ID=VALUE,Resistance,SourceWt)

#AOI weights
disturbance_R_AOI<-raster(file.path(spatialOutDir,'disturbance_R.tif')) %>%
  mask(AOI) %>%
  crop(AOI)
disturbance_W<-subs(disturbance_R_AOI, AreaDisturbance_LUT, by='ID',which='Resistance')

#Provincial weights
disturbance_WP<-subs(raster(file.path(spatialOutDir,'disturbance_R.tif')), AreaDisturbance_LUT, by='ID',which='Resistance')

#May add decay associated with roads...

##############
#Source  Layer
#Assign source weights to layer - based on values in spreadsheet built off raster's legend
#uses same layer disturbance layer but assigns different values

#AOI source
source_R_AOI<-disturbance_R_AOI
source_W<-subs(disturbance_R_AOI, AreaDisturbance_LUT, by='ID',which='SourceWt')

#Provincial source
source_WP<-subs(raster(file.path(spatialOutDir,'disturbance_R.tif')), AreaDisturbance_LUT, by='ID',which='SourceWt')

