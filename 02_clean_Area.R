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

#Clean Disturbance  Layer

#Assign weights to layer - based on values in spreadsheet built off raster's legend in data directory
#Example in the data/Archive folder
AreaDisturbance_LUT<-data.frame(read_excel(file.path(DataDir,'AreaDisturbance_LUT.xlsx'))) %>%
  dplyr::select(ID=disturb_Code,Resistance,SourceWt, BinaryHF)

#Provincial weights
disturbance_WP<-subs(raster(file.path(spatialOutDir,'disturbance_sfR.tif')), AreaDisturbance_LUT, by='ID',which='Resistance')
writeRaster(disturbance_WP, filename=file.path(spatialOutDir,'disturbance_WP'), format="GTiff", overwrite=TRUE)

#Binary Version
disturbanceB_WP<-subs(raster(file.path(spatialOutDir,'disturbance_sfR.tif')), AreaDisturbance_LUT, by='ID',which='BinaryHF')
disturbanceB_WP[disturbanceB_WP==0]<-NA
writeRaster(disturbanceB_WP, filename=file.path(spatialOutDir,'disturbanceB_WP'), format="GTiff", overwrite=TRUE)

#May add decay associated with roads...

##############
#Source  Layer
#Assign source weights to layer - based on values in spreadsheet built off raster's legend
#uses same layer disturbance layer but assigns different values

#Provincial source
source_WP<-subs(raster(file.path(spatialOutDir,'disturbance_R.tif')), AreaDisturbance_LUT, by='ID',which='SourceWt')
writeRaster(source_WP, filename=file.path(spatialOutDir,'source_WP'), format="GTiff", overwrite=TRUE)



##################
##Clipping to AOI
#AOI weights
disturbance_R_AOI<-raster(file.path(spatialOutDir,'disturbance_sfR.tif')) %>%
  mask(AOI) %>%
  crop(AOI)
writeRaster(disturbance_R_AOI, filename=file.path(spatialOutDir,'Prov_HumanDisturb'), format="GTiff", overwrite=TRUE)
disturbance_W<-subs(disturbance_R_AOI, AreaDisturbance_LUT, by='ID',which='Resistance')

#AOI source
source_R_AOI<-disturbance_R_AOI
source_W<-subs(disturbance_R_AOI, AreaDisturbance_LUT, by='ID',which='SourceWt')



