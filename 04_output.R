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

#Plot resistance and source layers
resistance_surface<-raster(file.path(CorrDir,"resistance_surface.tif"))

#resistance_surface<-resistance_surface %>%
#  mask(AOI) %>%
#
#crop(AOI)

resistance_surface_pts <- rasterToPoints(resistance_surface, spatial = TRUE)
# Then to a dataframe with colours - dont need colours for this iteration
resistance_surface_df<- data.frame(resistance_surface_pts)

HillShade_pts <- rasterToPoints(HillShade, spatial = TRUE)
# Then to a dataframe with colours - dont need colours for this iteration
HillShade_df<- data.frame(HillShade_pts)

#Given distribution of values make cut data to get even breaks
Rbreaks<-c(sort(unique(resistance_surface_df$layer)),10000)

resistance_surface_df <- resistance_surface_df %>%
  mutate(Resistance = cut(layer,
                      breaks = Rbreaks,
                      right=FALSE,
                      include.lowest=TRUE,
                      labels=FALSE
                      #labels = c(paste0('<=',(Rbreaks)[1:length(Rbreaks)-1]))
  )
  )
#Make mask for 1 & 2 category
resistance_mask<-resistance_surface_df[resistance_surface_df$layer %in% c(1,2),]

#png(file=file.path(figsOutDir,"Resistance.png"), units='mm', res = 1200)
pdf(file=file.path(figsOutDir,"Resistance.pdf"))
ggplot() +
  #plot BGC zones that persist in 2080
  geom_raster(data = resistance_surface_df, aes(x = x, y = y, fill = layer)) +
  #Colour using bcmaps bec colours
  scale_fill_viridis(option="viridis", direction=-1) +
  #scale_fill_discrete(name = "Resist", labels = as.character(10:length(Rbreaks))) +
  #scale_color_hue(labels = as.character(10:length(Rbreaks))) +
  new_scale_fill() +
  geom_raster(data = resistance_mask, aes(x = x, y = y, fill= layer), show.legend=FALSE) +
  scale_fill_gradient(low='white', high='white')  +
  new_scale_fill() +
  geom_tile(data=HillShade_df, aes(x = x, y = y, fill = hillshade_BC), alpha=0.4, show.legend=FALSE) +
  scale_fill_gradient(low='black', high='white')  +
  ggtitle("Human and Natural Resistance to species & ecosystem movement") +
  #add parks
  geom_sf(data=parks2017, fill = 'green', color = 'green', lwd=0.1, alpha=0.1) +
  #add study area boundary
  geom_sf(data=AOI, fill = NA, color= "black" ) +
  #add lakes and rivers
  geom_sf(data=lakes, fill = 'lightblue', color= 'lightblue', lwd=0 ) +
  geom_sf(data=rivers, fill = 'lightblue', color= 'lightblue' , lwd=0) +
  #Turn off axis and titles
  theme(axis.title = element_blank(),
        axis.ticks=element_blank(),
        axis.text=element_blank()) +
  #set background to blank
  theme(panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.background = element_blank())
dev.off()






