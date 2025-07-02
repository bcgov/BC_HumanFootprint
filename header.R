library(sf)
library(dplyr)
library(readr)
library(raster)
library(bcmaps)
library(fasterize)
library(readxl)
library(mapview)
library(WriteXLS)
library(foreign)
library(ggplot2)
library(ggnewscale)
library(viridis)
library(stars)
library(RCurl)

options(scipen=999)
options(warn = 1)
options(timeout=10000)

OutDir <- 'out'
dataOutDir <- file.path(OutDir,'data')
tileOutDir <- file.path(dataOutDir,'tile')
figsOutDir <- file.path(OutDir,'figures')
spatialOutDir <- file.path(OutDir,'spatial')
SpatialDir <- file.path('data','spatial')
RoadsDir<-file.path(SpatialDir,'roads')
DisturbDir<-file.path(SpatialDir,'disturb')
DataDir <- 'data'
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
#Change this to a local path for storing footprint data as input to conservation connectivity model
CorrDir<- file.path('/Users/darkbabine/Sync/_dev/Biodiversity/BC_ConservationConnectivity/data/spatial')
=======
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
######IMPORTANT#####
###Change this to a local path for storing footprint data as input to conservation connectivity model

CorrDir<- file.path('C:/Users/cestevo/Documents/GitHub/BC_ConservationConnectivity/out/spatial/ConnData')
#folder for landcover data around the province for boundary connectivity
CorrDir_LC<-file.path('C:/Users/cestevo/Documents/GitHub/BC_ConservationConnectivity/out/spatial/ConnData/lc')

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
#Local directory of GIS files such as HillShade for plotting
GISLibrary<- file.path('/Users/darkbabine/ProjectLibrary/Library/GISFiles/BC')

dir.create(file.path(OutDir), showWarnings = FALSE)
dir.create(file.path(dataOutDir), showWarnings = FALSE)
dir.create(file.path(tileOutDir), showWarnings = FALSE)
dir.create(file.path(RoadsDir), showWarnings = FALSE)
dir.create(file.path(DisturbDir), showWarnings = FALSE)
dir.create(file.path(figsOutDir), showWarnings = FALSE)
dir.create(DataDir, showWarnings = FALSE)
dir.create("tmp", showWarnings = FALSE)
dir.create("tmp/AOI", showWarnings = FALSE)
dir.create(file.path(spatialOutDir), showWarnings = FALSE)
<<<<<<< Updated upstream
=======
dir.create(file.path(SpatialDir), showWarnings = FALSE)
dir.create(file.path(CorrDir_LC), showWarnings = FALSE)
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





