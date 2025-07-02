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
  unique(roads_sf_in$DRA_ROAD_CLASS)
  unique(roads_sf_in$DRA_ROAD_SURFACE)
  unique(roads_sf_in$OG_DEV_PRE06_PETRLM_DEVELOPMENT_ROAD_TYPE)


### Check Petro roads
#Appears petro roads are typed with SURFACE and CLASSS
  table(roads_sf_in$DRA_ROAD_SURFACE,roads_sf_in$OG_DEV_PRE06_PETRLM_DEVELOPMENT_ROAD_TYPE)
  table(roads_sf_in$DRA_ROAD_CLASS,roads_sf_in$OG_DEV_PRE06_PETRLM_DEVELOPMENT_ROAD_TYPE)

#Additional petro road checks
  #Check if all petro roads have a OG_DEV_PRE06_PETRLM_DEVELOPMENT_ROAD_TYPE
 tt<-roads_sf_in %>%
  st_drop_geometry() %>%
  dplyr::filter(is.na(DRA_ROAD_CLASS))

  Petro_Tbl <- st_set_geometry(roads_sf_in, NULL) %>%
    count(OG_DEV_PRE06_PETRLM_DEVELOPMENT_ROAD_TYPE, LENGTH_METRES)

  roads_sf_petro <- roads_sf_in %>%
    mutate(DRA_ROAD_SURFACE=if_else(is.na(OG_DEV_PRE06_OG_PETRLM_DEV_RD_PRE06_PUB_ID),DRA_ROAD_SURFACE,'OGC')) %>%
    mutate(DRA_ROAD_CLASS=if_else(is.na(OG_DEV_PRE06_OG_PETRLM_DEV_RD_PRE06_PUB_ID),DRA_ROAD_CLASS,OG_DEV_PRE06_PETRLM_DEVELOPMENT_ROAD_TYPE))

  Petro_Tbl <- st_set_geometry(roads_sf_petro, NULL) %>%
    dplyr::count(DRA_ROAD_SURFACE, DRA_ROAD_CLASS)
#### End Petro road check

#Eliminate non-roads
  notRoadsCls <- c("ferry", "water", "Road Proposed")
  notRoadsSurf<-c("boat")

  roads_sf_1<-roads_sf_in %>%
    filter(!DRA_ROAD_CLASS %in% notRoadsCls,
           !DRA_ROAD_SURFACE %in% notRoadsSurf)

  HighUseCls<-c("Road arterial major","Road highway mabjor", "Road arterial minor","Road highway minor",
                "Road collector major","Road collector minor","Road ramp","Road freeway",
                "Road yield lane")

  ModUseCls<-c("Road local","Road recreation","Road alleyway","Road restricted",
               "Road service","Road resource","Road driveway","Road strata",
               "Road resource demographic", "Road strata","Road recreation demographic", "Trail Recreation",
               "Road runway", "Road runway non-demographic", "Road resource non-status","Road unclassified or unknown")

  LowUseCls<-c("Road lane","Road skid","Road trail","Road pedestrian","Road passenger",
               "Trail", "Trail demographic","Trail skid", "Road pedestrian mall")

  HighUseSurf<-c("paved")
  ModUseSurf<-c("loose","rough")
  LowUseSurf<-c("overgrown","decommissioned","seasonal","unknown")

  #Add new attribute that holds the use classificationr
  roads_sf <- roads_sf_1 %>%
    mutate(RoadUse = case_when((DRA_ROAD_CLASS %in% HighUseCls & DRA_ROAD_SURFACE %in% HighUseSurf) ~ 1, #high use
                               (DRA_ROAD_CLASS %in% LowUseCls | DRA_ROAD_SURFACE %in% LowUseSurf |
                                  (DRA_ROAD_SURFACE %in% ModUseSurf & is.na(DRA_ROAD_NAME_FULL)) |
                                  (is.na(DRA_ROAD_CLASS) & is.na(DRA_ROAD_SURFACE))) ~ 3,#low use
                               TRUE ~ 2)) # all the rest are medium use

  #Check the assignment
  Rd_Tbl <- st_set_geometry(roads_sf, NULL) %>%
    dplyr::count(DRA_ROAD_SURFACE, DRA_ROAD_CLASS, is.na(DRA_ROAD_NAME_FULL), RoadUse)

  #Data check
  nrow(roads_sf)-nrow(roads_sf_1)
  table(roads_sf$RoadUse)

  # Save as RDS for quicker access later.
  saveRDS(roads_sf, file = "tmp/DRA_roads_sf_clean.rds")
  # Also save as geopackage format for use in GIS and for buffer anlaysis below
  write_sf(roads_sf, file.path(spatialOutDir,"roads_clean.gpkg"))

  roads_sf<-readRDS(file = "tmp/DRA_roads_sf_clean.rds")

  #Use Stars to rasterize according to RoadUse and save as a tif
  #first st_rasterize needs a template to 'burn' the lines onto
  template = BCr_S
  template[[1]][] = NA
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
  roadsSR<-stars::st_rasterize(roads_sf[,"RoadUse"], template)
  write_stars(roadsSR,dsn=file.path(spatialOutDir,'roadsSR.tif'))
} else {
=======
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
  roadsR<-stars::st_rasterize(roads_sf[,"RoadUse"], template)
  write_stars(roadsR,dsn=file.path(spatialOutDir,'roadsSR.tif'))
  roadsR<-terra::rast(file.path(spatialOutDir,'roadsSR.tif'))

  ###removing some files to avoid memory issues:
  remove(roads_sf_petro)
  remove(roads_sf)
  remove(roads_sf_in)
  remove(roads_sf_1)


  } else {
>>>>>>> Stashed changes
  #Read in raster roads with values 0-none, 1-high use, 2-moderate use, 3-low use)
  roadsR<-raster(file.path(spatialOutDir,'roadsSR.tif'))
}

#Assign road weights for example: H-400, m-100, l-3 - based on values in the disturbance.xlsx spreadsheet in data directory
#Example in data directory Archive folder
LinearDisturbance_LUT<-data.frame(read_excel(file.path(DataDir,paste('LinearDisturbance.xlsx',sep='')),sheet='LinearDisturbance')) %>%
  dplyr::select(ID,Resistance,SourceWt,BinaryHF)

#By Prov, road weight - 1ha pixel - 50m each side of road
roads_WP<-subs(roadsR, LinearDisturbance_LUT, by='ID',which='Resistance')
writeRaster(roads_WP, filename=file.path(spatialOutDir,'roads_WP'), format="GTiff", overwrite=TRUE)
#Do Binary version
roadsB_W<-subs(roadsR, LinearDisturbance_LUT, by='ID',which='BinaryHF')
writeRaster(roadsB_W, filename=file.path(spatialOutDir,'roadsB_W'), format="GTiff", overwrite=TRUE)

#########
#Do similar analysis but split into 3 rasters, High(1), Med(2), Low(3)
#Generate buffers for each 500m for 1 100m and 500m for 2 and 50m for 3
#Use gpkg created above
roads_clean<-st_read(file.path(spatialOutDir,"roads_clean.gpkg"))

roadsH<-roads_clean %>%
  #st_drop_geometry() %>%
  #st_line_merge() %>%
  dplyr::filter(RoadUse==1) %>%
  mutate(RastID=1)

<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
roadsH1<- roadsH %>%
  st_buffer(dist=500) %>%
  st_union()
=======
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
####Buffering Roads and adding resistance weights####
#get each use level in a different raster:
roads_buf_file <- file.path(spatialOutDir,"roadsSR_buffered.tif")
>>>>>>> Stashed changes

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

<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
#Set Low roads - use previously processed Stars tif with 3 road use classes
roadsSR<-raster(file.path(spatialOutDir,'roadsSR.tif'))
roadsLR<-roadsSR
#Use only Low roads
roadsLR[roadsLR<3]<-NA
roadsLR[roadsLR==3]<-1
writeRaster(roadsLR, filename=file.path(spatialOutDir,'roadsLR'), format="GTiff", overwrite=TRUE)
=======
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
writeRaster(roadsR_buffered,file.path(spatialOutDir,"roadsSR_buffered.tif"),overwrite=T)

roadsR_buffered<-rast(file.path(spatialOutDir,"roadsSR_buffered.tif"))
saveRDS(roadsR_buffered,file.path(spatialOutDir,"roadsSR_buffered.rds"))

}else{
  roadsR_buffered<-rast(file.path(spatialOutDir,"roadsSR_buffered.tif"))

}


###Roads - source surface####


roadsB_W_file<-file.path(spatialOutDir,"roadsB_W.tif")
if (!file.exists(roadsB_W_file)) {

roadsB_W1<-subst(roadsR, c(1,2,3,0), c(NA,NA,1,NA))
roadsB_W_b<-buffer(roadsB_W1,width=100,background=NA)
roadsB_W<-subst(roadsB_W_b,c(0,1),c(0.75,.5))

writeRaster(roadsB_W, filename=file.path(spatialOutDir,'roadsB_W.tif'), overwrite=TRUE)
}else{
  roadsB_W<-rast(file.path(spatialOutDir,"roadsB_W.tif"))
}
>>>>>>> Stashed changes

##############
#Clip by AOI
roadsR_AOI<-roadsR %>%
  mask(AOI) %>%
  crop(AOI)
#roads_LUT<-data.frame(rdCode=c(1,2,3),weights=c(400,100,3))
roads_W<-subs(roadsR_AOI, LinearDisturbance_LUT, by='ID',which='Resistance')
writeRaster(roads_W, filename=file.path(spatialOutDir,'roads_W'), format="GTiff", overwrite=TRUE)



