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
  ProvRast<-rast(file.path(spatialOutDir,'ProvRast.tif'))
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
<<<<<<< Updated upstream
  Disturb_gdb <- list.files(file.path(DisturbDir), pattern = "gdb", full.names = TRUE)[1]
  st_layers(file.path(Disturb_gdb))
  #Read file and save to temp directory
  disturbance_sf_in <- read_sf(Disturb_gdb, layer = "BC_CEF_Human_Disturb_BTM_2023")
  saveRDS(disturbance_sf_in,file=dist_file)
=======
  disturbance_gdb <- list.files(file.path(SpatialDir,'BC_CEF_Human_Disturbance_2023'), pattern = "_Disturbance_", full.names = TRUE)[1]
  st_layers(disturbance_gdb)

  disturbance_sf <- read_sf(disturbance_gdb, layer = "BC_CEF_Human_Disturb_BTM_2023")

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

  saveRDS(disturbance_sf,file=dist_file)
  disturbance_sf<-readRDS(file=dist_file)

   disturbance_Tbl <- st_set_geometry(disturbance_sf, NULL) %>%
    count(CEF_DISTURB_SUB_GROUP, CEF_DISTURB_GROUP, disturb)
  WriteXLS(disturbance_Tbl,file.path(DataDir,'disturbance_Tbl.xlsx'))

  Unique_disturb<-unique(disturbance_sf$disturb)
  AreaDisturbance_LUT<-data.frame(disturb_Code=1:length(Unique_disturb),disturb=Unique_disturb)


  #Write out LUT and populate with resistance weights and source scores
  WriteXLS(AreaDisturbance_LUT,file.path(DataDir,'AreaDisturbance_LUT.xlsx'))

#Or use the following table.
#weights can be adjusted according to the needs of the reader.
  AreaDisturbance_LUT_lookup<-read.table(text=
               "disturb_Code	Resistance	SourceWt	BinaryHF	disturb
1	2	1	0	BTM - Alpine SubAlpine Barren
2	1	1	0	BTM - Forest Land
3	4	0	1	BTM - Fresh Water
4	32	0.5	1	BTM - Range Lands
5	1	1	0	BTM - Shrubs
6	1	1	0	BTM - Wetlands Estuaries
7	1	1	0	RESULTS_Reserves
8	64	0.25	1	Agriculture_and_Clearing
9	64	0.25	1	Cutblocks_Current
10	2	1	1	Cutblocks_Historic
11	81	0.2	1	Recreation
12	1000	0	1	Urban
13	16	0.3	1	ROW
14	25	0.4	1	Power
15	9	0.75	1	OGC_Infrastructure
16	25	0	1	Rail_and_Infrastructure
17	1000	0	1	Mining_and_Extraction
18	4	0.25	1	BTM - Glaciers and Snow
19	4	0	1	BTM - Salt Water
20	3	0.75	1	OGC_Geophysical",header=T,sep="\t")


  WriteXLS(AreaDisturbance_LUT_lookup,
           file.path(DataDir,'AreaDisturbance_LUT_lookup.xlsx'))



AreaDisturbance_LUT<-data.frame(read_excel(file.path(DataDir,'AreaDisturbance_LUT_lookup.xlsx'))) %>%
    dplyr::select(disturb,ID=disturb_Code,Resistance,SourceWt, BinaryHF)

  disturbance_sfR1 <- disturbance_sf %>%
    left_join(AreaDisturbance_LUT) %>%
    st_cast("MULTIPOLYGON")

  saveRDS(disturbance_sfR1,file='tmp/disturbance_sfR1')

  disturbance_sfR<- fasterize(disturbance_sfR1, raster(BCr), field="ID")

  saveRDS(disturbance_sfR,file='tmp/disturbance_sfR')
  writeRaster(disturbance_sfR, filename=file.path(spatialOutDir,'disturbance_sfR'), format="GTiff", overwrite=TRUE)

>>>>>>> Stashed changes
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

