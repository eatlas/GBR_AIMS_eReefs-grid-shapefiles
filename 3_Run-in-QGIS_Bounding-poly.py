# Running this script 
# This script must be run within the QGIS python console. 
import processing
import os.path
import glob
from os import path

# Location of everything relative to the QGIS map file. The paths must 
# work within QGIS. The map file is not in a subfolder.
basePath = QgsProject.instance().readPath(".")

# The input for this processing comes from the output from 1_grid2shapefile.R.
gridShpPath = basePath+'/export'
tmpPath = basePath+'/tmp'

def convertGrid2Boundary(gridShpFile, boundaryShpFile):
    # Check if input exists
    if not os.path.exists(gridShpFile):
        raise Exception('The '+gridShpFile+" doesn't exist. Have you run 2_grid2shapefile.R?")

    if not os.path.exists(boundaryShpFile):
        processing.run("native:dissolve", 
            {'INPUT':gridShpFile+'|layerid=0|subset=\"depth\">0','FIELD':[],'OUTPUT':boundaryShpFile})
    else:
        print("Skipping boundary conversion as it already exists. Delete it to recalculate this file: "+boundaryShpFile)
    
convertGrid2Boundary(
    gridShpPath+'/GBR_AIMS_eReefs-grid-shapefiles_GBR4-hydro-v2.shp', 
    gridShpPath+'/GBR_AIMS_eReefs-grid-shapefiles_GBR4-hydro-v2_boundary.shp')
    
convertGrid2Boundary(
    gridShpPath+'/GBR_AIMS_eReefs-grid-shapefiles_GBR1-hydro-v2.shp', 
    gridShpPath+'/GBR_AIMS_eReefs-grid-shapefiles_GBR1-hydro-v2_boundary.shp')
    
# This function takes an existing fine scale boundary file and creates a
# low detail version of the boundary suitable for quick checking if points
# are inside the grid. A buffer is applied to the fine boundary to ensure
# that the lowDetailBoundaryShapeFile does not produce false negatives. i.e.
# indicating that the point is outside the boundary when it is infact inside
# the grid. With the AIMS eReefs data extraction tool it can perform Inverse
# Distance Weighted interpolation on the extractions which means that it can
# estimate values that fall just outside the eReefs model grid. For this reason
# we don't want the tool to complain to the user that they have selected a site 
# that there is no data for, but infact the tool can produce data through interpolation
# over a small distance.
# boundaryShpFile - High resolution boundary file
# tempShpFile - Intermediate shapefile after the buffering is applied.
# lowDetailBoundaryShpFile - Output simplified boundary file
# bufferDist - buffering to be applied to the grid. The simplification will be 2 x 
#       buffer distance. Note: This is units of degrees.
def createLowDetailBoundary(boundaryShpFile, tempShpFile, lowDetailBoundaryShpFile, bufferDist):
    if not os.path.exists(lowDetailBoundaryShpFile):
        # Make sure the temporary directory exists
        if not os.path.exists(os.path.dirname(tempShpFile)):
            os.mkdir(os.path.dirname(tempShpFile))
        processing.run("native:buffer", 
            {'INPUT':boundaryShpFile,'DISTANCE':bufferDist,'SEGMENTS':5,'END_CAP_STYLE':0,'JOIN_STYLE':0,'MITER_LIMIT':2,'DISSOLVE':True,'OUTPUT':tempShpFile})
        processing.run("native:simplifygeometries", {'INPUT':tempShpFile,'METHOD':0,'TOLERANCE':2*bufferDist,'OUTPUT':lowDetailBoundaryShpFile})        
    else:
        print("Skipping low detail boundary as it already exists. Delete it to recalculate this file: "+lowDetailBoundaryShpFile)

createLowDetailBoundary(
    gridShpPath+'/GBR_AIMS_eReefs-grid-shapefiles_GBR4-hydro-v2_boundary.shp',
    tmpPath+'/GBR4-buffer.shp',
    gridShpPath+'/GBR_AIMS_eReefs-grid-shapefiles_GBR4-hydro-v2_ld-boundary.geojson', 0.04)
    
createLowDetailBoundary(
    gridShpPath+'/GBR_AIMS_eReefs-grid-shapefiles_GBR1-hydro-v2_boundary.shp',
    tmpPath+'/GBR1-buffer.shp',
    gridShpPath+'/GBR_AIMS_eReefs-grid-shapefiles_GBR1-hydro-v2_ld-boundary.geojson', 0.01)