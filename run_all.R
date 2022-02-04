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

source('header.R')

#only run load if neccessary - clean
source("01_load.R")
#Clips input to AOI - current options include:
AOI <- BC #Province

#AOI <- ws %>% #Watershed
#  filter(SUB_SUB_DRAINAGE_AREA_NAME == "Bulkley")

#AOI <- EcoRegions %>% #EcoRegion
#  filter(ECOREGION_NAME == "EASTERN HAZELTON MOUNTAINS")

#clean will clip to AOI
source("02_clean.R")

#read in user defined weighting table

source("03_analysis.R")

source("04_output.R")

