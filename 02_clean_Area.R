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
disturb_file <- file.path(spatialOutDir,"disturbance_sfR.tif")
if (!file.exists(disturb_file)) {
    #disturbance_sf<-readRDS(file=dist_file)

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
  disturbance_sf<-readRDS(file=disturb_file)
  disturbance_sfR<-raster(file.path(spatialOutDir,'disturbance_sfR.tif'))
}


#Assign weights to layer - based on values in spreadsheet built off raster's legend in data directory
AreaDisturbance_LUT<-data.frame(read_excel(file.path(DataDir,'AreaDisturbance_LUTH.xlsx'))) %>%
  dplyr::select(ID=disturb_Code,Resistance,SourceWt, BinaryHF)

#Provincial weights
<<<<<<< Updated upstream
disturbance_WP<-subs(raster(file.path(spatialOutDir,'disturbance_sfR.tif')), AreaDisturbance_LUT, by='ID',which='Resistance')
writeRaster(disturbance_WP, filename=file.path(spatialOutDir,'disturbance_WP'), format="GTiff", overwrite=TRUE)
=======
disturbance_WP_file <- file.path(spatialOutDir,"disturbance_WP.tif")
if (!file.exists(disturbance_WP_file)) {
  disturbance_WP<-subst(rast(file.path(spatialOutDir,'disturbance_sfR.tif')), AreaDisturbance_LUT$ID,to=AreaDisturbance_LUT$Resistance)
  writeRaster(disturbance_WP, file.path(spatialOutDir,'disturbance_WP.tif'), overwrite=TRUE)

 }else{
   disturbance_WP<-raster(file.path(spatialOutDir,'disturbance_WP.tif'))
 }


>>>>>>> Stashed changes

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
<<<<<<< Updated upstream
source_WP<-subs(raster(file.path(spatialOutDir,'disturbance_sfR.tif')), AreaDisturbance_LUT, by='ID',which='SourceWt')
writeRaster(source_WP, filename=file.path(spatialOutDir,'source_WP'), format="GTiff", overwrite=TRUE)
=======
source_WP_file <- file.path(spatialOutDir,"source_WP.tif")
if (!file.exists(source_WP_file)) {

source_WP<-subst(rast(file.path(spatialOutDir,'disturbance_sfR.tif')), AreaDisturbance_LUT$ID,AreaDisturbance_LUT$SourceWt)
writeRaster(source_WP, filename=file.path(spatialOutDir,'source_WP.tif'), overwrite=TRUE)
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes

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



