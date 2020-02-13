# Running this script 
# This script must be run within the QGIS python console. 
import processing
import os.path
from os import path

# Location of everything relative to the QGIS map file. The paths must 
# work within QGIS. The map file is not in a subfolder.
basePath = QgsProject.instance().readPath(".")

# The input for this processing comes from the output from 1_grid2shapefile.R.
gridShpPath = basePath+'/export'

def convertGrid2Boundary(gridShpFile, boundaryShpFile):
    # Check if input exists
    if not os.path.exists(gridShpFile):
        raise Exception('The '+gridShpFile+" doesn't exist. Have you run 1-grid-shp/1_grid2shapefile.R?")

    if not os.path.exists(boundaryShpFile):
        processing.run("native:dissolve", 
            {'INPUT':gridShpFile+'|layerid=0|subset=\"dfData\">0','FIELD':[],'OUTPUT':boundaryShpFile})
    
convertGrid2Boundary(
    gridShpPath+'/GBR_AIMS_eReefs-grid-shapefiles_GBR4-hydro-v2.shp', 
    gridShpPath+'/GBR_AIMS_eReefs-grid-shapefiles_GBR4-hydro-v2_boundary.shp')
    
convertGrid2Boundary(
    gridShpPath+'/GBR_AIMS_eReefs-grid-shapefiles_GBR1-hydro-v2.shp', 
    gridShpPath+'/GBR_AIMS_eReefs-grid-shapefiles_GBR1-hydro-v2_boundary.shp')
