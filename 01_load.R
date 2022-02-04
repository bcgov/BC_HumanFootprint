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
#processed roads from bc_raster_roads repo
#Need to split roads into high-medium-low use rasters for assigning footprint weights
#Roads<-raster(file.path(SpatialDir,'RoadDensR.tif'), crs=Prov_crs)
#crs(Roads)  <- Prov_crs
roads_sf_in <- readRDS(file.path(NALibrary,"Disturbance/Integrated_roads_sf.rds"))

#Provincial Human Disturbance Layers - compiled for CE
#Needs refinement to differentiate rural/urban and old vs young cutblocks, rangeland, etc.
dist_file<-'tmp/disturbance_sf'
if (!file.exists(dist_file)) {
  disturbance_gdb <- list.files(file.path(NALibrary, "Disturbance/CEF_Disturbance/Disturbance_2021"), pattern = ".gdb", full.names = TRUE)[1]
  disturbance_list <- st_layers(disturbance_gdb)

  disturbance_sf <- read_sf(disturbance_gdb, layer = "BC_CEF_Human_Disturb_BTM_2021_merge")
  saveRDS(disturbance_sf,file=dist_file)
  disturbance_sf<-readRDS(file=dist_file)
  #Fasterize disturbance subgroup
  disturbance_Tbl <- st_set_geometry(disturbance_sf, NULL) %>%
    count(CEF_DISTURB_SUB_GROUP, CEF_DISTURB_GROUP)
  #Fix non-unique sub group codes
  disturbance_sf <- disturbance_sf %>%
    mutate(disturb = case_when(!(CEF_DISTURB_SUB_GROUP %in% c('Baseline Thematic Mapping', 'Historic BTM', 'Historic FAIB', 'Current FAIB')) ~ CEF_DISTURB_GROUP,
                               (CEF_DISTURB_GROUP == 'Agriculture_and_Clearing' & CEF_DISTURB_SUB_GROUP == 'Baseline Thematic Mapping') ~ 'Agriculture_and_Clearing',
                               (CEF_DISTURB_GROUP == 'Mining_and_Extraction' & CEF_DISTURB_SUB_GROUP == 'Baseline Thematic Mapping') ~ 'Mining_and_Extraction',
                               (CEF_DISTURB_GROUP == 'Urban' & CEF_DISTURB_SUB_GROUP == 'Baseline Thematic Mapping') ~ 'Urban',
                               (CEF_DISTURB_GROUP == 'Cutblocks' & CEF_DISTURB_SUB_GROUP == 'Current FAIB') ~ 'Cutblocks_Current',
                                (CEF_DISTURB_GROUP == 'Cutblocks' & CEF_DISTURB_SUB_GROUP == 'Historic FAIB') ~ 'Cutblocks_Historic',
                                 (CEF_DISTURB_GROUP == 'Cutblocks' & CEF_DISTURB_SUB_GROUP == 'Historic BTM') ~ 'Cutblocks_Historic',
                                  TRUE ~ 'Unkown'))

   disturbance_Tbl <- st_set_geometry(disturbance_sf, NULL) %>%
    count(CEF_DISTURB_SUB_GROUP, CEF_DISTURB_GROUP, disturb)
  WriteXLS(disturbance_Tbl,file.path(DataDir,'disturbance_Tbl.xlsx'))

  Unique_disturb<-unique(disturbance_sf$disturb)
  AreaDisturbance_LUT<-data.frame(disturb_Code=1:length(Unique_disturb),disturb=Unique_disturb)


  #Write out LUT and populate with resistance weights and source scores
  WriteXLS(AreaDisturbance_LUT,file.path(DataDir,'AreaDisturbance_LUT.xlsx'))

AreaDisturbance_LUT<-data.frame(read_excel(file.path(DataDir,'AreaDisturbance_LUT.xlsx'))) %>%
    dplyr::select(disturb,ID=disturb_Code,Resistance,SourceWt, BinaryHF)

  disturbance_sfR1 <- disturbance_sf %>%
    left_join(AreaDisturbance_LUT) %>%
    st_cast("MULTIPOLYGON")

  disturbance_sfR<- fasterize(disturbance_sfR1, BCr, field="ID")

  saveRDS(disturbance_sfR,file='tmp/disturbance_sfR')
  writeRaster(disturbance_sfR, filename=file.path(spatialOutDir,'disturbance_sfR'), format="GTiff", overwrite=TRUE)

} else {
  disturbance_sf<-readRDS(file=dist_file)
  disturbance_sfR<-raster(file.path(spatialOutDir,'disturbance_sfR.tif'))

}


##########################
#Layers for doing AOI for testing and printing

#Ecosections
EcoS_file <- file.path("tmp/EcoS")
ESin <- read_sf(file.path(SpatialDir,'Ecosections/Ecosections.shp')) %>%
  st_transform(3005)
EcoS <- st_cast(ESin, "MULTIPOLYGON")
saveRDS(EcoS, file = EcoS_file)

#EcoRegions
EcoRegions<-bcmaps::ecoregions()

#Watersheds
ws <- get_layer("wsc_drainages", class = "sf") %>%
  dplyr::select(SUB_DRAINAGE_AREA_NAME, SUB_SUB_DRAINAGE_AREA_NAME) %>%
  dplyr::filter(SUB_DRAINAGE_AREA_NAME %in% c("Nechako", "Skeena - Coast"))
st_crs(ws)<-3005
saveRDS(ws, file = "tmp/ws")
write_sf(ws, file.path(spatialOutDir,"ws.gpkg"))

