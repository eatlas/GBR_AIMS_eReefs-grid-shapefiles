# ereefs-grid-shapefile
Eric Lawrey - Australian Institute of Marine Science - 10 Feb 2020

This repository contains scripts that create shapefile versions of the GBR1 and GBR4 grids used in the eReefs models. This repository's purpose is to facilitate recreation of the dataset. 

[Download this dataset](https://eatlas.org.au/data/uuid/43ff162c-8132-41cd-8547-76a1acf58105) from the matching metadata record.

eReefs models the waters of the Great Barrier Reef. It has a hydrodynamic model, which estimates the movement and physical properties of the water (temperature, tides, salinity, currents) and a biogeochemical model that captures what is in the water (sediments, nutrients, plankton, etc.). Both these models are simulated on a 4 km (GBR4) and 1 km (GBR1) curvilinear grid. The 1 km version of the models are driven at their boundary by the 4 km model. 

This dataset is an extract of the grid used in these models in a format that can be easily viewed in a GIS application. These were developed to allow maps to be made that show the extent of the eReefs models (boundary) and the detail of the models (grid cells). This conversion extracts polygons for the grid with one polygon per pixel. It does not extract the data from the NetCDF model data. It does however record the depth from the model (botz variable) with each polygon.

![Dataset preview map](/images/dataset-preview-map.jpeg)
This map shows a preview of the four shapefiles in this dataset. On the left are the two bounding polygons for the two grids (GBR1 and GBR4) and the right maps show a close up of the grid cells. Viewing the grid at the whole GBR scale results in flat colour as the grid cells are so small.

## Execution requirements
To recreate this dataset you will need the following tools to be installed:
 - R with ncdf4 and maptools libraries
 - QGIS 
and > 30 GB disk space to handle the downloaded eReefs NetCDF source data files.

## Step 1 - Download GBR1 and GBR4 eReefs NetCDF files
This dataset consists of shapefiles corresponding to the two grids (GBR1 and GBR4) used in eReefs modelling (https://ereefs.org.au). This conversion needs an example GBR4 and GBR1 NetCDF data file from which to extract the grids. These files are so large (> 30 GB) that they are not included in this repository and so must be downloaded from the original source at http://dapds00.nci.org.au/thredds/catalogs/fx3/catalog.html. This script does not care about the date of the files. It simply extracts the latitude and longitude grid and the botz (depth) variable from the files provided to it. For eReefs the grid doesn't vary over time and so only one file from a model run is necessary. Additionally the eReefs hydrodynamic (V2) and the eReefs biogeochemical models (v924, v2.x, v3.x) share a common model grid and so we only bother to extract the grid from the hydrodynamic model data files.

Example files are:
- GBR4: http://dapds00.nci.org.au/thredds/fileServer/fx3/gbr4_v2/gbr4_simple_2020-01.nc
- GBR1: http://dapds00.nci.org.au/thredds/fileServer/fx3/gbr1_2.0/gbr1_simple_2020-01-14.nc

These files should be saved in C:\temp for the script to access them. Alternatively the paths in the R script can be adjusted.

## Step 2 - Convert eReefs grid in NetCDF file to shapefile polygon (2_grid2shapefile.R)
This script needs to be run in R with the ncdf4 and maptools libraries installed. These libraries can be installed by running the following in the R console:

 install.packages(c("ncdf4", "maptools"))

This script converts the eReefs NetCDF data file downloaded in Step 1 into a shapefile. It extracts a polygon for each of the grid cells. This script does not copy over all the NetCDF data, but instead only copies over the bathymetry of the grid cells (botz variable) to allow the 'wet' cells of the model to be visualised. The depth attribute is saved as the depth attribute in the shapefile. It can be plotted to see where the wet cells in the model grid are.

## Step 3 - eReefs model boundary - Dissolve the shapefile polygon (3_grid_Boundary-poly.qgz, 3_Run-in-QGIS_Bounding-poly.py)
In this step we calculate the boundary for each eReefs model. These can be used to get an overview of where the eReefs models can be used, without the clutter of the grid being visualised. The boundary polygon is calculated by dissolving all the 'wet' cell polygons from step 2 into a single polygon. This script uses the processing capabilities of QGIS. To run this script you need QGIS installed. This script should be run from the Python Console in QGIS. To do so use the 'Show Editor' in the Python console, then 'Open script...', followed by 'Run Script'.

![Loading 3_Run-in-QGIS_Bounding-poly.py to run in QGIS](/images/loading-script-qgis.jpg)

The QGIS map file 2_grid_Boundary-poly.qgz is essentially a blank map and is used as a document to run the script in. Opening this QGIS map sets the working directory for the python script, ensuring that all the relative paths work correctly. 

This script also calculates a low detail GeoJSON version of these boundary polygons. These are intended to be used in the [AIMS eReefs extraction tool](https://extraction.ereefs.aims.gov.au) to detect points added by the user that are outside the model boundaries.

## Step 4 - Dataset preview maps (4_dataset-preview-map.qgz)
The preview map for this dataset was created in QGIS using the 4_dataset-preview-map.qgz. Load this map in QGIS then open the Project/Layout Manager. Select the 'Dataset preview' then Layout/Export As Image...
This map relies on a basemap from the eAtlas service.

## Generated Directories
- export 
	This directory contains the shapefiles of the eReefs grids generated by the 2_grid2shapefile.R and 3_Run-in-QGIS_Bounding-poly.py scripts 

## License
The code for this dataset is made available via an MIT license. The resulting dataset shapefiles are make available under a Creative Commons Attribution 3.0 Australian license (https://creativecommons.org/licenses/by/3.0/au/).