# Eric Lawrey - Australian Institute of Marine Science
# Converts the eReefs curvilinear grid in the NetCDF file to a shapefile
# This conversion just converts the grid into a set of polygons 
# so that the grid can be rendered on a GIS map. Attached to the polygons
# is the value of the model depth (botz from the NetCDF file, dfData in the shapefile). 
# Where this variable is no NaN the grid cell is wet in the model and so should
# have data available at the surface.

# This script is written to create shapefiles for the two grids
# used in eReefs modelling (https://ereefs.org.au).
# This conversion needs an example GBR4 and GBR1 data files from 
# which to extract the grids. These files are so large that they
# are not saved as part of these scripts (as they are >30GB). 
# They can be downloaded from
# http://dapds00.nci.org.au/thredds/catalogs/fx3/catalog.html
# Example files are:
# http://dapds00.nci.org.au/thredds/fileServer/fx3/gbr4_v2/gbr4_simple_2020-01.nc
# http://dapds00.nci.org.au/thredds/fileServer/fx3/gbr1_2.0/gbr1_simple_2020-01-14.nc
# 
# These files should be saved in C:\temp for the script to access them. 
# Alternatively adjust the path in the script to the files.

library(ncdf4)
library(maptools)
source('curvilinearFuncs.R')



createDepthShpFile <- function (outname, ncfile) {
  nc <- nc_open(ncfile)
  varData <- ncvar_get( nc, nc$var$botz, start=c(1,1), count=nc$var$botz$varsize )
  lat <- ncvar_get(nc, 'latitude')
  long <- ncvar_get(nc, 'longitude')
  polys <- toPolygons(lat, long, data.frame(botz=as.vector(varData)))
  
  
  prjStr <-'GEOGCS["GCS_WGS_1984",DATUM["D_WGS_1984",SPHEROID["WGS_1984",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]]'
  cat(prjStr, file=paste0(outname,'.prj'))
  writePolyShape(polys,outname)
  
  IDOneBin <- cut(polys[,1], range(polys[,1]), include.lowest=TRUE)
  NcDissolve   <- unionSpatialPolygons(NorthCaroProj ,IDOneBin)
  NcDissolvePSOne <- SpatialPolygons2PolySet(NcDissolve)
  writePolyShape(NcDissolvePSOne,paste0(outname,'-bounds'))
}

outname <- 'export/GBR_AIMS_eReefs-GBR4-hydro-grid_depth'
ncfile <- 'C:/temp/gbr4_simple_2020-01.nc'
print('===== Creating GBR 4 grid shapefile ====')
createDepthShpFile(outname, ncfile)

#outname <- 'export/GBR_AIMS_eReefs-GBR1-hydro-grid_depth'
#ncfile <- 'C:/temp/gbr1_simple_2020-01-14.nc'
#print('===== Creating GBR 1 grid shapefile ====')
#createDepthShpFile(outname, ncfile)


