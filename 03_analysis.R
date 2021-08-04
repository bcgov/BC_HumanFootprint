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

# Copyright 2020 Province of British Columbia
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

source('header.R')

#Combine roads and disturbance areas - assign max weight to pixel
disturbanceStack<-stack(roads_WP,disturbance_WP)

resistance_surface<-max(disturbanceStack,na.rm=TRUE)
writeRaster(resistance_surface, filename=file.path(CorrDir,'resistance_surface.tif'), format="GTiff", overwrite=TRUE)

writeRaster(roads_W, filename=file.path(CorrDir,'roads_W.tif'), format="GTiff", overwrite=TRUE)
writeRaster(disturbance_W, filename=file.path(CorrDir,'disturbance_W.tif'), format="GTiff", overwrite=TRUE)


#Take the stack of human disturbance rasters and apply weights
#Then take maximum weight for each cell and pass as resistance surface to BC_ConservationCorridor






#Combine Linear rasters portion of human footprint selecting max value
LinearDecay<-max(LinearDecay01,LinearDecay05,LinearDecay10)
writeRaster(LinearDecay, filename=file.path(spatialOutDir,paste("intactLayers/LinearDecay",sep="")), format="GTiff",overwrite=TRUE)
LinearDecay<-raster(file.path(spatialOutDir,'intactLayers/LinearDecay.tif'))

#Make Human Foot Print raster - max of 3 area based weight groups
HF <- max(HF01,HF05,HF10, na.rm=TRUE)
writeRaster(HF, filename=file.path(spatialOutDir,paste("intactLayers/HFootprint",sep="")), format="GTiff",overwrite=TRUE)
HF<-raster(file.path(spatialOutDir,'intactLayers/HFootprint.tif'))

#Make Human Foot Print raster - max of Human Footprint and Linear Feature surface

HF_LD <- max(HF, LinearDecay, na.rm=TRUE)

HF_LD<-HF_LD %>%
  projectRaster(crs=Prov_crs, method='ngb')

writeRaster(HF_LD, filename=file.path(spatialOutDir,paste("intactLayers/HFootprint_LinearDecay",sep="")), format="GTiff",overwrite=TRUE)




