

download.file(url="https://www.cec.org/files/atlas_layers/1_terrestrial_ecosystems/1_01_0_land_cover_2020_30m/land_cover_2020v2_30m_tif.zip",
              file.path(SpatialDir,"landcover_2020_NA.zip"),mode="wb")

unzip(file.path(SpatialDir,"landcover_2020_NA.zip"), exdir = SpatialDir)

lc_na<-rast(file.path(SpatialDir,"land_cover_2020v2_30m_tif/NA_NALCMS_landcover_2020v2_30m/data/NA_NALCMS_landcover_2020v2_30m.tif"))

#removing some heavy objects
rm(disturbance_sf)
rm(roads_sf_in)
rm(cblock_sf_raster)

gc()

#get a point in the continent of bc to define which polygon should be buffered for landcover
point_continent<-c(-123,54) %>% st_point() %>%  st_sfc(crs = 4326) %>% st_transform(crs=st_crs(bc))

#get the continent portion of bc:
bc_cont<-bc[which(st_intersects(point_continent,bc,sparse=F)),]

bcboarder_bf_pos<-st_buffer(st_cast(bc_cont,"MULTIPOLYGON") %>% st_union() %>%
                              st_simplify(),dist=30000)


bcboarder_bf_neg<-st_buffer(st_cast(bc_cont,"MULTIPOLYGON") %>% st_union() %>%
                              st_simplify(),dist=-30000)

BC_buf<-st_difference(bcboarder_bf_pos,bcboarder_bf_neg)

#Convert to terra vector
BC_buf<-vect(BC_buf)

BC_buf_reproj<-terra::project(BC_buf,lc_na)

lc_na_BC<-terra::crop(lc_na,BC_buf_reproj,mask=T)

#Saving for easy of use:
writeRaster(lc_na_BC,file.path(spatialOutDir,"NA_BC_landcover_2020_buffered.tif"),
            overwrite=T)

lc_na_BC<-rast(file.path(spatialOutDir,"NA_BC_landcover_2020_buffered.tif"))

classes_lc<-unique(lc_na_BC) %>% mutate(Code=rownames(.))

#These classes were retrieved from the metadata of the source layer

resistance_lc<-c(rep(1,9),64,2,10000,4,4)
source_lc<-c(rep(1,9),0.25,1,0,0,0.25)

definition_table<-classes_lc %>% mutate(Resistance=resistance_lc,
                                              Source=source_lc)

resistance_lc_bc<-subst(lc_na_BC,
      from=definition_table$Class_EN,
      to=definition_table$Resistance)


source_lc_bc<-subst(lc_na_BC,
                        from=definition_table$Class_EN,
                        to=definition_table$Source)

writeRaster(resistance_lc_bc,file.path(spatialOutDir,"resistance_lc_bc.tif"),overwrite=T)
writeRaster(source_lc_bc,file.path(spatialOutDir,"source_lc_bc.tif"),overwrite=T)

###splitting the restistance/source raster in sections
splits<-divide(resistance_lc_bc,n=6)
crs(splits)<-crs(resistance_lc_bc)
resistance_lc_bc_l<-list()
source_lc_bc_l<-list()

for(i in 1:length(splits)){
  resistance_lc_bc_l[[i]]<-crop(resistance_lc_bc,splits[i],mask=T,
                                filename=paste0(CorrDir_LC,"/resistance_lc_bc","_",i,"_of_",length(splits),".tif"),
                                )
  }


for(i in 1:length(splits)){
  source_lc_bc_l[[i]]<-crop(source_lc_bc,splits[i],mask=T,
                                filename=paste0(CorrDir_LC,"/source_lc_bc","_",i,"_of_",length(splits),".tif"),
  )
}
