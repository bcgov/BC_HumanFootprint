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

#Output the rasters to the data/spatial directory of the conservation connectivity  repo (BC_ConservationConnectivity)
writeRaster(resistance_surface, filename=file.path(CorrDir,'resistance_surface.tif'), format="GTiff", overwrite=TRUE)

#writeRaster(roads_W, filename=file.path(CorrDir,'roads_W.tif'), format="GTiff", overwrite=TRUE)
#writeRaster(disturbance_W, filename=file.path(CorrDir,'disturbance_W.tif'), format="GTiff", overwrite=TRUE)

writeRaster(source_surface, filename=file.path(CorrDir,'source_surface.tif'), format="GTiff", overwrite=TRUE)

