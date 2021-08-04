library(sf)
library(dplyr)
library(readr)
library(raster)
library(bcmaps)
library(rgdal)
library(fasterize)
library(readxl)
library(mapview)

OutDir <- 'out'
dataOutDir <- file.path(OutDir,'data')
tileOutDir <- file.path(dataOutDir,'tile')
figsOutDir <- file.path(OutDir,'figures')
spatialOutDir <- file.path(OutDir,'spatial')
SpatialDir <- file.path('data','spatial')
DataDir <- 'data'
ESIDir <- file.path('/Users/darkbabine/Dropbox (BVRC)/Projects/ESI')
CorrDir<-file.path('/Users/darkbabine/Dropbox (BVRC)/_dev/Biodiversity/BC_ConservationCorridors/data/spatial')


dir.create(file.path(OutDir), showWarnings = FALSE)
dir.create(file.path(dataOutDir), showWarnings = FALSE)
dir.create(file.path(tileOutDir), showWarnings = FALSE)
dir.create(file.path(figsOutDir), showWarnings = FALSE)
dir.create(DataDir, showWarnings = FALSE)
dir.create("tmp", showWarnings = FALSE)
dir.create("tmp/AOI", showWarnings = FALSE)
dir.create(file.path(spatialOutDir), showWarnings = FALSE)





