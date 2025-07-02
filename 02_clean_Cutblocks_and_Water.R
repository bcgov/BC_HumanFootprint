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

#Assign weights to layer - based on age of cutbocks
#this is built off the spreadsheet built off raster's legend in data directory
#More recent cutblocks will have the same resistance level as the current level from the lookup table

#Load the excel file created previously and get the cutblokcs only
AreaDisturbance_LUT<-data.frame(read_excel(file.path(DataDir,'AreaDisturbance_LUT_lookup.xlsx'))) %>%
  filter(grepl("Cutblock",disturb)) %>%
  dplyr::select(ID=disturb_Code,Resistance,SourceWt, BinaryHF)

#Getting the lowest and highest age of the cutblocks
minmax_cutblock_age<-c(
  cellStats(raster(file.path(spatialOutDir,'cblock_sf_raster.tif')),"min"),
  cellStats(raster(file.path(spatialOutDir,'cblock_sf_raster.tif')),"max")
  )


#Create a lookup table
AreaDisturbance_LUT_cblock<-data.frame(Resistance=seq(from=min(AreaDisturbance_LUT$Resistance),max(AreaDisturbance_LUT$Resistance),length.out=10),
           SourceWt=seq(from=max(AreaDisturbance_LUT$SourceWt),min(AreaDisturbance_LUT$SourceWt),length.out=10),
          Age=seq(min(minmax_cutblock_age),max(minmax_cutblock_age),length.out=10),
          BinaryHF=1) %>% mutate_at(c("Resistance",'Age'),round)

training_data<-data.frame(Age=c(1900,1928,1983,2011,2025),
           Resistance=c(1,1,15,45,64))

model_cb<-lm(log(Resistance)~ 1+Age,data=training_data)

AreaDisturbance_LUT_cblock$Resistance=round(exp(predict(model_cb,newdata=AreaDisturbance_LUT_cblock)))


#Create a matrix to reclassify the cutblock raster:
AreaDisturbance_LUT_cblock$Age2<- AreaDisturbance_LUT_cblock$Age %>% lag(default=0)

AreaDisturbance_LUT_cblock_reclass<-AreaDisturbance_LUT_cblock %>% dplyr::select(Age2,Age,Resistance) %>%
  as.matrix()

#Provincial weights
cblock_sf_raster_WP_file <- file.path(spatialOutDir,"cblock_sf_raster_WP.tif")
if (!file.exists(cblock_sf_raster_WP_file)) {
  cblock_sf_raster_WP<-classify(rast(file.path(spatialOutDir,'cblock_sf_raster.tif')),
                                  rcl=AreaDisturbance_LUT_cblock_reclass,
                                  include.lowest=T)

  writeRaster(cblock_sf_raster_WP, filename=file.path(spatialOutDir,'cblock_sf_raster_WP.tif'), overwrite=TRUE)

 }else{
   cblock_sf_raster_WP<-rast(file.path(spatialOutDir,'cblock_sf_raster_WP.tif'))
 }


##############
#Source  Layer
#Similarly to the above, but now for source weight
AreaSource_LUT_cblock_reclass<-AreaDisturbance_LUT_cblock %>% dplyr::select(Age2,Age,SourceWt) %>%
  as.matrix()

#Provincial source
source_cutblock_file <- file.path(spatialOutDir,"source_cutblock.tif")


if (!file.exists(source_cutblock_file)) {

  source_cutblock<-classify(rast(file.path(spatialOutDir,'cblock_sf_raster.tif')),
                        rcl=AreaSource_LUT_cblock_reclass)
writeRaster(source_cutblock, file.path(spatialOutDir,"source_cutblock.tif"), overwrite=TRUE)

}else{
  source_cutblock<-rast(file.path(spatialOutDir,'source_cutblock.tif'))
}

##################

#Buffering freshwater and reclassifying so that resistance increases inwards of freshwater

#Get sf of disturbance and filter for water polygons
#it is easier to buffer polygons than the raster
water_file<-file.path(spatialOutDir,'water_buffered.tif')


BCr <- rast(BCr_file)

buffer_fun<-function(x){
  a<-x %>% mutate(Resistance=14)  %>% vect() %>% terra::buffer(width=-500)%>% rasterize(y=BCr,field="Resistance")
  b<-x %>% mutate(Resistance=12) %>% vect() %>% terra::buffer(width=-400) %>% rasterize(y=BCr,field="Resistance")
  c<-x %>% mutate(Resistance=10) %>% vect() %>% terra::buffer(width=-300) %>% rasterize(y=BCr,field="Resistance")
  d<-x %>% mutate(Resistance=8)  %>% vect()%>% terra::buffer(width=-200)%>% rasterize(y=BCr,field="Resistance")
  e<-x %>% mutate(Resistance=6)  %>% vect()%>% terra::buffer(width=-100)%>% rasterize(y=BCr,field="Resistance")
  f<-x %>% mutate(Resistance=4) %>% vect()%>% rasterize(y=BCr,field="Resistance")



  l<-list(a,b,c,d,e,f)


  return(l)

}

if (!file.exists(water_file)) {


water_sf<-disturbance_sf %>% filter(CEF_DISTURB_GROUP=="BTM - Fresh Water") %>% st_cast("MULTIPOLYGON")
water_sf_buf<-buffer_fun(water_sf)
water_buffered<-rast(water_sf_buf) %>% max(na.rm=T)

writeRaster(water_buffered,water_file,overwrite=T)

saveRDS(water_buffered,file='tmp/water_buffered.rds')

water_buffered<-readRDS(file='tmp/water_buffered.rds')


#Source raster:
water_source<-subst(water_buffered,from=c(14,12,10,8,6,4),to=c(0,0,0,0,0,0),others=NA)


writeRaster(water_source,
            filename=file.path(spatialOutDir,'water_source.tif'),
            overwrite=T)

saveRDS(water_source,file='tmp/water_source.rds')


}else{

  water_buffered<-readRDS(file='tmp/water_buffered.rds')
  water_source<-readRDS(file='tmp/water_source.rds')

}




