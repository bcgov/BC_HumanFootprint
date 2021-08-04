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

#Provincial Raster to place rasters in the same reference
BCr_file <- file.path(spatialOutDir,"BCr.tif")
if (!file.exists(BCr_file)) {
  ProvRast<-raster(nrows=15744, ncols=17216, xmn=159587.5, xmx=1881187.5,
                   ymn=173787.5, ymx=1748187.5,
                   crs=Prov_crs,
                   res = c(100,100), vals = 1)
  BCr <- fasterize(bcmaps::bc_bound_hres(class='sf'),ProvRast)
  BCr_S <-st_as_stars(BCr)
  write_stars(BCr_S,dsn=file.path(spatialOutDir,'BCr_S.tif'))
  writeRaster(BCr, filename=BCr_file, format="GTiff", overwrite=TRUE)
  writeRaster(ProvRast, filename=file.path(spatialOutDir,'ProvRast'), format="GTiff", overwrite=TRUE)
} else {
  BCr <- raster(BCr_file)
  ProvRast<-raster(file.path(spatialOutDir,'ProvRast.tif'))
  BCr_S <- read_stars(file.path(spatialOutDir,'BCr_S.tif'))
}

#################
#processed roads from bc_raster_roads repo
#Need to split roads into high-medium-low use rasters for assigning footprint weights
#Roads<-raster(file.path(SpatialDir,'RoadDensR.tif'), crs=Prov_crs)
#crs(Roads)  <- Prov_crs
roads_sf_in <- readRDS(file.path(SpatialDir,"Integrated_roads_sf.rds"))

#Provincial Human Disturbance Layers - compiled for CE
#Needs refinement to differentiate rural/urban and old vs young cutblocks, rangeland, etc.
dist_file<-'tmp/disturbance_sf'
if (!file.exists(dist_file)) {
  disturbance_gdb <- list.files(file.path(SpatialDir, "Disturbance"), pattern = ".gdb", full.names = TRUE)[1]
  disturbance_list <- st_layers(disturbance_gdb)

  disturbance_sf <- read_sf(disturbance_gdb, layer = "BC_CEF_Human_Disturbance_and_BTM_2019_Provincial_Merge")
  saveRDS(disturbance_sf,file=dist_file)
} else {
  disturbance_sf<-readRDS(file=dist_file)
}

#Error when clipping disturbance_sf - likely due to bad topology
#Error in CPL_geos_op2(op, x, y) :
#Evaluation error: ParseException: Unknown WKB type 12.
# disturbance_sf_AOI<-disturbance_sf %>%
#    st_intersection(AOI)
#  saveRDS(disturbance_sf_AOI,file='tmp/disturbance_sf_AOI')
#unique(st_geometry_type(st_geometry(disturbance_sf)))

#Read in CE disturbance raster and clip to area
disturbance_R<-raster(file.path(SpatialDir,'Disturbance/raster/cefdist21.tif')) %>%
  resample(BCr,method='ngb') #allign raster to standard Provincial hectares BC base
writeRaster(disturbance_R, filename=file.path(spatialOutDir,'disturbance_R.tif'), format="GTiff", overwrite=TRUE)

##########################
#Layers for doing AOI for testing

#ESI boundary - for testing, etc.
ESI_file <- file.path("tmp/ESI")
if (!file.exists(ESI_file)) {
  #Load ESI boundary
  ESIin <- read_sf(file.path(ESIDir,'Data/Skeena_ESI_Boundary'), layer = "ESI_Skeena_Study_Area_Nov2017") %>%
    st_transform(3005)
  ESI <- st_cast(ESIin, "MULTIPOLYGON")
  saveRDS(ESI, file = ESI_file)
} else
  ESI<-readRDS(file = ESI_file)

#Ecosections
EcoS_file <- file.path("tmp/EcoS")
ESin <- read_sf(file.path(SpatialDir,'Ecosections/Ecosections.shp')) %>%
  st_transform(3005)
EcoS <- st_cast(ESin, "MULTIPOLYGON")
saveRDS(EcoS, file = EcoS_file)

#SkeenaSalmonStudyBoundary
SalmS_file <- file.path("tmp/SalmS")
SalmSin <- read_sf(file.path(SpatialDir,'SkeenaSalmonStudyBd/SkeenaSalmonStudyBd.shp')) %>%
  st_transform(3005)
SalmS <- st_cast(SalmSin, "MULTIPOLYGON")
saveRDS(SalmS, file = SalmS_file)

ws <- get_layer("wsc_drainages", class = "sf") %>%
  dplyr::select(SUB_DRAINAGE_AREA_NAME, SUB_SUB_DRAINAGE_AREA_NAME) %>%
  dplyr::filter(SUB_DRAINAGE_AREA_NAME %in% c("Nechako", "Skeena - Coast"))
st_crs(ws)<-3005
saveRDS(ws, file = "tmp/ws")
write_sf(ws, file.path(spatialOutDir,"ws.gpkg"))




