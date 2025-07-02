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

roads_WP<-raster(file.path(spatialOutDir,'roads_WP.tif')) #Low - 3, Medium - 100, High 400 weighting
disturbance_WP<-raster(file.path(spatialOutDir,'disturbance_WP.tif')) #1 to 1000 weighting depending on type
disturbanceB_WP<-raster(file.path(spatialOutDir,'disturbanceB_WP.tif')) #Binary - disturbed/not disturbed

#Assign human footprint resistance_surface
#Combine roads and disturbance areas - assign max weight to pixel
<<<<<<< Updated upstream
disturbanceStack<-stack(roads_WP,disturbance_WP)
resistance_surface_WP<-max(disturbanceStack,na.rm=TRUE) # combine and take highest weight
=======
disturbanceStack<-rast(list(disturbance_WP,roadsR_buffered,cblock_sf_raster_WP,water_buffered))
resistance_surface_WP<-max(disturbanceStack,na.rm=T)

#clip to boundary:
resistance_surface_WP<-crop(resistance_surface_WP,BC,mask=T)

#saving
resistance_surface_WP<-writeRaster(resistance_surface_WP,file.path(spatialOutDir,'resistance_surface_WP.tif'),overwrite=T)
>>>>>>> Stashed changes
saveRDS(resistance_surface_WP,file='tmp/resistance_surface_WP')

#Assign source_surface for connectivity
source_surface<-raster(file.path(spatialOutDir,'source_WP.tif'))

#Make binary HF
#Buffer roads by 500m
roadsB_W<-raster(file.path(spatialOutDir,'roadsB_W.tif'))
roadsB_W[roadsB_W == 0] <- NA
#writeRaster(roadsB_W, filename=file.path(spatialOutDir,'roadsB_W'), format="GTiff", overwrite=TRUE)
roadsB_buff <- buffer(roadsB_W, width=500)
writeRaster(roadsB_buff, filename=file.path(spatialOutDir,'roadsB_buff.tif'), format="GTiff", overwrite=TRUE)

roadsB_W_S <- read_stars(file.path(spatialOutDir,'roadsB_W.tif'))
roadsB_W_S_sf<-st_as_sf(roadsB_W_S, as_points=FALSE, na.rm=TRUE)
write_sf(roadsB_W_S_sf, file.path(spatialOutDir,"roadsB_W_S_sf.gpkg"), overwrite=TRUE)

roadsB_W_S_sf<-read_sf(file.path(spatialOutDir,'roadsB_W_S_sf.gpkg'))

roadsB_W_S_sf_U<-st_union(roadsB_W_S_sf, by_feature=FALSE)
write_sf(roadsB_W_S_sf_U, file.path(spatialOutDir,"roadsB_W_S_sf_U.gpkg"), overwrite=TRUE)

roadsB_W_S_sf_U<-read_sf(file.path(spatialOutDir,'roadsB_W_S_sf_U.gpkg'))
roadsB_S_buff<-st_buffer(roadsB_W_S_sf_U, 500)

write_sf(roadsB_S_buff, file.path(spatialOutDir,"roadsB_S_buff.gpkg"), overwrite=TRUE)


HumanFPStack<-stack(roadsB_buff,disturbanceB_WP)
HumanFP_Binary<-max(HumanFPStack,na.rm=TRUE)
writeRaster(HumanFP_Binary, filename=file.path(spatialOutDir,'HumanFP_Binary.tif'), format="GTiff", overwrite=TRUE)

#########
resistance_surface<-resistance_surface_WP %>%
  mask(AOI) %>%
  crop(AOI)

#Assign source_surface
<<<<<<< Updated upstream
source_surface<-source_WP %>%
  mask(AOI) %>%
  crop(AOI)
=======
source_surface<-rast(list(roadsB_W, #secondary roads as source only, buffered
                          source_cutblock, #cutblocks
                          water_source, #freshwater, buffered
                          source_WP)) #other sources
source_surface<-min(source_surface,na.rm = T)

#clip to boundary:
source_surface<-crop(source_surface,BC,mask=T)

#Saving
writeRaster(source_surface,file.path(spatialOutDir,'source_surface.tif'),overwrite=T)
saveRDS(source_surface,file='tmp/source_surface.rds')
source_surface<-readRDS('tmp/source_surface.rds')

>>>>>>> Stashed changes


