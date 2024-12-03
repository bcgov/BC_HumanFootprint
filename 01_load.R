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

#Rasterize the Province for subsequent masking
# bring in BC boundary
bc <- bcmaps::bc_bound()
Prov_crs<-crs(bc)
#Prov_crs<-"+proj=aea +lat_1=50 +lat_2=58.5 +lat_0=45 +lon_0=-126 +x_0=1000000 +y_0=0 +datum=NAD83 +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0"

#Provincial Raster to place rasters in the same geo reference
BCr_file <- file.path(spatialOutDir,"BCr.tif")
if (!file.exists(BCr_file)) {
  BC<-bcmaps::bc_bound_hres(class='sf')
  saveRDS(BC,file='tmp/BC')
  ProvRast<-raster(nrows=15744, ncols=17216, xmn=159587.5, xmx=1881187.5,
                   ymn=173787.5, ymx=1748187.5,
                   crs=Prov_crs,
                   res = c(100,100), vals = 1)
  ProvRast_S<-st_as_stars(ProvRast)
  write_stars(ProvRast_S,dsn=file.path(spatialOutDir,'ProvRast_S.tif'))
  BCr <- fasterize(BC,ProvRast)
  #Linear rasterization of roads works better using the stars package
  BCr_S <-st_as_stars(BCr)
  write_stars(BCr_S,dsn=file.path(spatialOutDir,'BCr_S.tif'))
  writeRaster(BCr, filename=BCr_file, format="GTiff", overwrite=TRUE)
  writeRaster(ProvRast, filename=file.path(spatialOutDir,'ProvRast'), format="GTiff", overwrite=TRUE)
} else {
  BCr <- raster(BCr_file)
  ProvRast<-raster(file.path(spatialOutDir,'ProvRast.tif'))
  BCr_S <- read_stars(file.path(spatialOutDir,'BCr_S.tif'))
  BC <-readRDS('tmp/BC')
}

#################
#Download latest CE integrated roads layer - current is 2024
rd_file<-'tmp/roads_sf_in'
if (!file.exists(rd_file)) {
  #Download CE road data -   #https://catalogue.data.gov.bc.ca/dataset/bc-cumulative-effects-framework-integrated-roads-current
  url<-'https://coms.api.gov.bc.ca/api/v1/object/1d3d61b0-1f33-4608-837a-ee0b0ac4264e'
  CE_rd<-"CE_roads.zip"
  #use URL to download CE road file
  download.file(url, file.path(RoadsDir, CE_rd), mode = "wb")
  #unzip into roads directory with 'gdb' holder file
  unzip(file.path(RoadsDir,CE_rd), exdir = file.path(RoadsDir,'CE_roads.gdb'),junkpaths=TRUE)
  #Read gdb and select layer for sf_read
  Roads_gdb <- list.files(file.path(RoadsDir), pattern = "gdb", full.names = TRUE)[1]
  st_layers(file.path(Roads_gdb))
  #Read file and save to temp directory
  roads_sf_in <- read_sf(Roads_gdb, layer = "integrated_roads_2024")
  saveRDS(roads_sf_in,file=rd_file)
} else {
  roads_sf_in<-readRDS(file=rd_file)
}

##Download latest Provincial Human Disturbance Layers compiled for CE - current is 2023
#Needs refinement to differentiate rural/urban and old vs young cutblocks, rangeland, etc.
dist_file<-'tmp/disturbance_sf'
if (!file.exists(dist_file)) {
  #Download CE road data -  https://catalogue.data.gov.bc.ca/dataset/bc-cumulative-effects-framework-human-disturbance-current
  url<-'https://coms.api.gov.bc.ca/api/v1/object/ecea4b04-055a-49d1-8910-60d726d2d1bf'
  CE_dist<-"CE_disturb.zip"
  #use URL to download CE road file
  download.file(url, file.path(DisturbDir, CE_dist), mode = "wb")
  #unzip into disturbance directory with 'gdb' holder file
  unzip(file.path(DisturbDir,CE_dist), exdir = file.path(DisturbDir,'CE_disturb.gdb'),junkpaths=TRUE)
  #Read gdb and select layer for sf_read
  Disturb_gdb <- list.files(file.path(DisturbDir), pattern = "gdb", full.names = TRUE)[1]
  st_layers(file.path(Disturb_gdb))
  #Read file and save to temp directory
  disturbance_sf_in <- read_sf(Disturb_gdb, layer = "BC_CEF_Human_Disturb_BTM_2023")
  saveRDS(disturbance_sf_in,file=dist_file)
} else {
  disturbance_sf_in<-readRDS(file=dist_file)
}

message('Breaking')
break

############


##########################
#Layers for doing AOI for testing and printing

EcoS<-bcmaps::ecosections()

#EcoRegions
EcoRegions<-bcmaps::ecoregions()

#Watersheds
ws <- get_layer("wsc_drainages", class = "sf") %>%
  dplyr::select(SUB_DRAINAGE_AREA_NAME, SUB_SUB_DRAINAGE_AREA_NAME) %>%
  dplyr::filter(SUB_DRAINAGE_AREA_NAME %in% c("Nechako", "Skeena - Coast"))
st_crs(ws)<-3005
saveRDS(ws, file = "tmp/ws")
write_sf(ws, file.path(spatialOutDir,"ws.gpkg"))

