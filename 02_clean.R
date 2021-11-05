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
               "service","resource","driveway","strata")
  LowUseCls<-c("lane","skid","trail","pedestrian","passenger")

  HighUseSurf<-c("paved")
  ModUseSurf<-c("loose")
  LowUseSurf<-c("overgrown","decommissioned","rough","seasonal","unknown")

  #Add new attribute that holds the use classification
  roads_sf <- roads_sf_1 %>%
    mutate(RoadUse = case_when((ROAD_CLASS %in% HighUseCls & ROAD_SURFACE %in% HighUseSurf) ~ 1, #high use
                               (ROAD_CLASS %in% LowUseCls | ROAD_SURFACE %in% LowUseSurf |
                                  (ROAD_SURFACE %in% ModUseSurf & is.na(ROAD_NAME_FULL)) |
                                  (is.na(ROAD_CLASS) & is.na(ROAD_SURFACE))) ~ 3,#low use
                               TRUE ~ 2)) # all the rest are medium use

  #Check the assignment
  Rd_Tbl <- st_set_geometry(roads_sf, NULL) %>%
    count(ROAD_SURFACE, ROAD_CLASS, RoadUse)

  nrow(roads_sf)-nrow(roads_sf_1)

  # Save as RDS for quicker access later.
  saveRDS(roads_sf, file = "tmp/DRA_roads_sf_clean.rds")
  # Also save as geopackage format for use in GIS
  write_sf(roads_sf, "out/data/roads_clean.gpkg")
  roads_sf<-readRDS(file = "tmp/DRA_roads_sf_clean.rds")

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
#Example in the project root folder
LinearDisturbance_LUT<-data.frame(read_excel(file.path(dataOutDir,paste('LinearDisturbance.xlsx',sep='')),sheet='LinearDisturbance')) %>%
  dplyr::select(ID,Resistance,SourceWt,BinaryHF)

#By AOI
roadsR_AOI<-roadsR %>%
  mask(AOI) %>%
  crop(AOI)
#roads_LUT<-data.frame(rdCode=c(1,2,3),weights=c(400,100,3))
roads_W<-subs(roadsR_AOI, LinearDisturbance_LUT, by='ID',which='Resistance')

#By Prov
roads_WP<-subs(roadsR, LinearDisturbance_LUT, by='ID',which='Resistance')
writeRaster(roads_WP, filename=file.path(spatialOutDir,'roads_WP'), format="GTiff", overwrite=TRUE)
roads_WP<-raster(file.path(spatialOutDir,'roads_WP.tif'))
roadsB_W<-subs(roadsR, LinearDisturbance_LUT, by='ID',which='BinaryHF')
writeRaster(roadsB_W, filename=file.path(spatialOutDir,'roadsB_W'), format="GTiff", overwrite=TRUE)

#########
#Do similar analysis but split into 3 rasters, High(1), Med(2), Low(3)
#Generate buffers for each 500m for 1 100m annd 500m for 2 and 50m for 3
roads_clean<-st_read(file.path(NALibrary,'Disturbance/roads_clean.gpkg'))

roadsH<-roads_clean %>%
  #st_drop_geometry() %>%
  #st_line_merge() %>%
  dplyr::filter(RoadUse==1) %>%
  mutate(RastID=1)

roadsH1<- roadsH %>%
  st_buffer(dist=500) %>%
  st_union()

write_sf(roadsH1, file.path(spatialOutDir,"roadsH1.gpkg"), overwrite=TRUE)
roadsH1<-st_read(file.path(spatialOutDir,"roadsH1.gpkg")) %>%
  mutate(RastVal=1)
roadsHR<-roadsH1 %>%
  fasterize(BCr,field="RastVal")

writeRaster(roadsHR, filename=file.path(spatialOutDir,'roadsHR'), format="GTiff", overwrite=TRUE)

###Medium Roads at 100 and 500
roadsM<-roads_clean %>%
  #st_drop_geometry() %>%
  #st_line_merge() %>%
  dplyr::filter(RoadUse==2) %>%
  mutate(RastID=1)

roadsM1<- roadsM %>%
  st_buffer(dist=100) %>%
  st_union()

write_sf(roadsM1, file.path(spatialOutDir,"roadsM1.gpkg"), overwrite=TRUE)
roadsM1<-st_read(file.path(spatialOutDir,"roadsM1.gpkg")) %>%
  mutate(RastVal=1)

roadsMR<-roadsM1 %>%
  fasterize(BCr,field="RastVal")

writeRaster(roadsMR, filename=file.path(spatialOutDir,'roadsMR'), format="GTiff", overwrite=TRUE)

###Do medium use at 500
roadsM1_500<- roadsM %>%
  st_buffer(dist=500) %>%
  st_union()

write_sf(roadsM1_500, file.path(spatialOutDir,"roadsM1_500.gpkg"), overwrite=TRUE)
roadsM1_500<-st_read(file.path(spatialOutDir,"roadsM1_500.gpkg")) %>%
  mutate(RastVal=1)

roadsMR500<-roadsM1_500 %>%
  fasterize(BCr,field="RastVal")

writeRaster(roadsMR500, filename=file.path(spatialOutDir,'roadsMR500'), format="GTiff", overwrite=TRUE)

#Set Low roads - use previously processed Stars tif with 3 road use classes
roadsSR<-raster(file.path(spatialOutDir,'roadsSR.tif'))
roadsLR<-roadsSR
#Use only Low roads
roadsLR[roadsLR<3]<-NA
roadsLR[roadsLR==3]<-1
writeRaster(roadsLR, filename=file.path(spatialOutDir,'roadsLR'), format="GTiff", overwrite=TRUE)

##############
#Disturbance  Layer
#Assign weights to layer - based on values in spreadsheet built off raster's legend
#Example in the project root folder
AreaDisturbance_LUT<-data.frame(read_excel(file.path(dataOutDir,'AreaDisturbance_LUT.xlsx'))) %>%
  dplyr::select(ID=disturb_Code,Resistance,SourceWt, BinaryHF)

#AOI weights
disturbance_R_AOI<-raster(file.path(spatialOutDir,'disturbance_sfR.tif')) %>%
  mask(AOI) %>%
  crop(AOI)
writeRaster(disturbance_R_AOI, filename=file.path(spatialOutDir,'Prov_HumanDisturb'), format="GTiff", overwrite=TRUE)
disturbance_W<-subs(disturbance_R_AOI, AreaDisturbance_LUT, by='ID',which='Resistance')

#Provincial weights
disturbance_WP<-subs(raster(file.path(spatialOutDir,'disturbance_sfR.tif')), AreaDisturbance_LUT, by='ID',which='Resistance')
writeRaster(disturbance_WP, filename=file.path(spatialOutDir,'disturbance_WP'), format="GTiff", overwrite=TRUE)
disturbance_WP<-raster(file.path(spatialOutDir,'disturbance_WP.tif'))

disturbanceB_WP<-subs(raster(file.path(spatialOutDir,'disturbance_sfR.tif')), AreaDisturbance_LUT, by='ID',which='BinaryHF')
disturbanceB_WP[disturbanceB_WP==0]<-NA

writeRaster(disturbanceB_WP, filename=file.path(spatialOutDir,'disturbanceB_WP'), format="GTiff", overwrite=TRUE)


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
writeRaster(source_WP, filename=file.path(spatialOutDir,'source_WP'), format="GTiff", overwrite=TRUE)
source_WP<-raster(file.path(spatialOutDir,'source_WP.tif'))

#Clip map features
parks2017<-readRDS(file= 'tmp/parks2017') %>%
  st_buffer(dist=0) %>%
  st_intersection(AOI)
saveRDS(parks2017, file = 'tmp/AOI/parks2017')

HillShade <-raster(file.path(GISLibrary,'GRIDS/hillshade_BC.tif')) %>%
  mask(AOI) %>%
  crop(AOI)

lakes<-readRDS(file= 'tmp/lakes') %>%
  st_buffer(dist=0) %>%
  st_intersection(AOI)
saveRDS(lakes, file = 'tmp/AOI/lakes')

rivers<-readRDS(file= 'tmp/rivers') %>%
  st_buffer(dist=0) %>%
  st_intersection(AOI)
saveRDS(rivers, file = 'tmp/AOI/rivers')
