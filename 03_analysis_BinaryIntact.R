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

#Assign resistance_surface
#Combine roads and disturbance areas - assign max weight to pixel
disturbanceB_WP<-raster(file.path(spatialOutDir,'disturbanceB_WP.tif'))
roadsHR<-raster(file.path(spatialOutDir,'roadsHR.tif'))
roadsMR<-raster(file.path(spatialOutDir,'roadsMR.tif'))
roadsML<-raster(file.path(spatialOutDir,'roadsLR.tif'))

BinaryStack<-stack(disturbanceB_WP, roadsHR, roadsMR, roadsLR)
HFBinary<-max(BinaryStack,na.rm=TRUE)
IntactBinary<-HFBinary
IntactBinary[IntactBinary>0]<-2
IntactBinary[is.na(IntactBinary)]<-1
IntactBinary[IntactBinary==2]<-NA

writeRaster(IntactBinary, filename=file.path(spatialOutDir,'IntactBinary.tif'), format="GTiff", overwrite=TRUE)


