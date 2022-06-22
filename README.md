<!-- Add a project state badge
See https://github.com/BCDevExchange/Our-Project-Docs/blob/master/discussion/projectstates.md
If you have bcgovr installed and you use RStudio, click the 'Insert BCDevex Badge' Addin. -->

# BC_HumanFootprint

This repository presents an analysis that generates 2 raster layers: 1)
a human footprint/human disturbance layer; and 2) a ‘source’ layer that
weights land/water cover according to how likely they will provide
habitat. The layers are assigned resistance and source weights following
McRae et al 2016
<https://www.conservationgateway.org/ConservationByGeography/NorthAmerica/UnitedStates/oregon/science/Documents/McRae_et_al_2016_PNW_CNS_Connectivity.pdf>.

### Data

This analysis uses the Province’s Cumulative Effects consolidated roads
and disturbance layers.

The consolidated roads are available from the B.C. Data Catalogue
(<https://catalogue.data.gov.bc.ca/dataset/ce-roads-2021>). They are
based on the British Columbia [Digital Road Atlas available from the
B.C. Data
Catalogue]((https://catalogue.data.gov.bc.ca/dataset/bb060417-b6e6-4548-b837-f9060d94743e))
and distributed under the [Access Only - B.C. Crown
Copyright](https://www2.gov.bc.ca/gov/content?id=1AAACC9C65754E4D89A118B875E0FBDA)
licence.

The consolidated disturbance is available from the B.C. Data Catalogue
(<https://catalogue.data.gov.bc.ca/dataset/ce-disturbance-2021>). added)

### Usage

There are a set of core scripts that are required for the analysis, a
run_all.R script is used to control their execution:

-   01_load.R
-   02_clean_Area.R
-   02_clean_Raods.R
-   03_analysis.R
-   03_analysis_BinaryIntact.R
-   04_output.R

The repo will download the CE disturbance and road layers from the BC
Data Catalogue. An excel spreadsheet of disturbance and source weights
should be in the data directory. An area of interest (AOI) can be used
to clip data for testing - links to EcoSection, EcoRegion and watersheds
are provided. Warning Provincial scale analysis is computationally
intensive.

### Project Status

This project is part of a Provincial conservation assessment being led
by the Ministry of Environment and Climate Change Strategy. The analysis
is exploratory.

Updates to the disturbance layer is required, including: seperating
urban into 1) high, 2) low density, and 3) rural; Modifying cut blocks
by age to have recent and historic; Modifying range to differentiate
front and back country range.

Roads are rasterized at 100m and assumes that the ‘footprint’ of a road
extends 50m on either side of the mid line. Potential modifications
include generating a distance to road surface with an assigned a decay
value based on road type.

Other modifications include buffering water and ocean and applying
varying weights based on distance from shore.

### Getting Help or Reporting an Issue

To report bugs/issues/feature requests, please file an
[issue](https://github.com/bcgov/BC_HumanFootprint/issues/).

### How to Contribute

If you would like to contribute, please see our
[CONTRIBUTING](CONTRIBUTING.md) guidelines.

Please note that this project is released with a [Contributor Code of
Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree
to abide by its terms.

### License

    Copyright 2021 Province of British Columbia

    Licensed under the Apache License, Version 2.0 (the &quot;License&quot;);
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an &quot;AS IS&quot; BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and limitations under the License.

------------------------------------------------------------------------

*This project was created using the
[bcgovr](https://github.com/bcgov/bcgovr) package.*

This repository is maintained by
[ENVEcosystems](https://github.com/orgs/bcgov/teams/envecosystems/members).
