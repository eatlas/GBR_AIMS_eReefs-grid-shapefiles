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
# are not saved as part of these scripts (as they are >30GB). We don't
# download them in the script due to their size.
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


# Make the working directory match the location of this script. This
# will ensure the relative paths make sense.
# https://stackoverflow.com/questions/3452086/getting-path-of-an-r-script/35842176#35842176
setwd(utils::getSrcDirectory(function(x) {x})[1])

gbr4ncfile <- 'C:/temp/gbr4_simple_2020-01.nc'
gbr1ncfile <- 'C:/temp/gbr1_simple_2020-01-14.nc'


#
# Given the original points x generate the 'o' points using the distances
# between the a's
#  o1    o2    o3
#     a1    a2
#  o4    o5    o6
#     a3    a4  
#  o7    o8    o9
# Note the array would normally be much bigger than that shown above
# and the algorithm must work in this case.
#x <- matrix(c(0,10,20,1,11,21,2,12,23),nrow=3,ncol=3)
#x <- matrix(c(0,0,0,10,10,10,20,20,20),nrow=3,ncol=3)
#x <- matrix(c(0,1,2,3,10,11,12,13,20,21,22,23),nrow=4,ncol=3)
# Take a maxtrix of X values or Y values
# Adapted from NcWMS - CurvilinearGrid.java
makeCorners <- function (midPoints) {
    ncols <- ncol(midPoints)
    nrows <- nrow(midPoints)
    edges <- matrix(0, nrows+1, ncols+1)
    a1 <- midPoints[1:nrows-1,1:ncols-1]
    # Shift down 1
    a3 <- midPoints[2:nrows,1:ncols-1]
    # Shift across 1
    a2 <- midPoints[1:nrows-1,2:ncols]
    # Shift down and across 1
    a4 <- midPoints[2:nrows,2:ncols]

    edges[2:nrows,2:ncols] <- (a1+a2+a3+a4)/4
    
    # Extrapolate to left and right exterior points
    edges[2:nrows,1] <- edges[2:nrows,2] - (edges[2:nrows,3] - edges[2:nrows,2])
    edges[2:nrows,ncols+1] <- edges[2:nrows,ncols] + (edges[2:nrows,ncols] - edges[2:nrows,ncols-1])
    
    # Extrapolate to the first and last rows
    edges[1,] <- edges[2,] - (edges[3,] - edges[2,])
    edges[nrows+1,] <- edges[nrows,] + (edges[nrows,] - edges[nrows-1,])
    
    return(edges)
}

# Create a polygon around each four corner coordinates (o1 ...). 
# The corners can be calculated using makeCorners
# lat and long should correspond to the coordinates for o1 ...
#  o1    o2    o3
#     a1    a2
#  o4    o5    o6
#     a3    a4  
#  o7    o8    o9
# The centre coordinates a1 ... correspond to the centroids of 
# the original grid.
# 
# From
# http://stackoverflow.com/questions/26620373/spatialpolygons-creating-a-set-of-polygons-in-r-from-coordinates
# 
#polys <- SpatialPolygons(
#    mapply(
#        function(poly, id) {
#            xy <- matrix(poly, ncol=2, byrow=TRUE)
#            Polygons(list(Polygon(xy)), ID=id)
#        }, 
#        split(square, row(square)), ID)
#    )

# Create a matrix of polygon coordinates
# Returns a SpatialPolygonsDataFrame with a data frame containing
# the grid cell indicies of each polygon.
# Data must be full grid with one row per grid cell.
toPolygons <- function(lat, long, data) {
    pts <- proc.time()
    # Calculate corners around the lat and long locations
    # These matricies will be one row and column larger
    # than lat and long.
    longGrid <- makeCorners(long)
    latGrid <- makeCorners(lat)
    nrows <- nrow(latGrid)
    ncols <- ncol(longGrid)
    
    # Assertion checks
    if (nrow(latGrid) != nrow(longGrid)) {
        stop(paste("nrows of latGrid and longGrid don't match:",nrow(latGrid),nrow(longGrid)))
    }
    if (ncol(latGrid) != ncol(longGrid)) {
        stop(paste("ncol of latGrid and longGrid don't match:",ncol(latGrid),ncol(longGrid)))
    }
    if (nrow(lat) != nrow(long)) {
        stop(paste("nrows of lat and long don't match:",nrow(lat),nrow(long)))
    }
    if (ncol(lat) != ncol(long)) {
        stop(paste("ncol of lat and long don't match:",ncol(lat),ncol(long)))
    }
    if (nrow(latGrid)!=(nrow(lat)+1)) {
        stop(paste0("latGrid (",nrow(latGrid),
            ") should have one more row than lat (",nrow(latGrid),"), it doesn't"))
    }
    if (ncol(latGrid)!=(ncol(lat)+1)) {
        stop(paste0("latGrid (",ncol(latGrid),
            ") should have one more column than lat (",ncol(latGrid),"), it doesn't"))
    }
    if (nrow(longGrid)!=(nrow(long)+1)) {
        stop(paste0("longGrid (",nrow(longGrid),
            ") should have one more row than long (",nrow(longGrid),"), it doesn't"))
    }
    if (ncol(longGrid)!=(ncol(long)+1)) {
        stop(paste0("longGrid (",ncol(longGrid),
            ") should have one more column than long (",ncol(longGrid),"), it doesn't"))
    }
    
    if (ncol(lat) *nrow(lat) != nrow(data)) {
        stop(paste0("Data length does not match the grid size"))
    }
    
    y1 <- as.vector(latGrid[1:nrows-1,1:ncols-1])
    # Shift down 1
    y2 <- as.vector(latGrid[2:nrows,1:ncols-1])
    # Shift across 1
    y4 <- as.vector(latGrid[1:nrows-1,2:ncols])
    # Shift down and across 1
    y3 <- as.vector(latGrid[2:nrows,2:ncols])
    
    x1 <- as.vector(longGrid[1:nrows-1,1:ncols-1])
    # Shift down 1
    x2 <- as.vector(longGrid[2:nrows,1:ncols-1])
    # Shift across 1
    x4 <- as.vector(longGrid[1:nrows-1,2:ncols])
    # Shift down and across 1
    x3 <- as.vector(longGrid[2:nrows,2:ncols])
    
    boxesRaw <- cbind(x1,y1,x2,y2,x3,y3,x4,y4,x1,y1)
    
    # Assertion
    if (nrow(boxesRaw) != (nrow(lat) * ncol(lat))) {
        stop("There should be one boxesRaw per cell in lat, there aren't")
    }
    
    # Some boxes will have NaN elements in them.
    # Should remove all boxes with any NaN corners as
    # the polygon creation will fail.
    goodboxIndicies <- complete.cases(boxesRaw)
    
    boxes <- boxesRaw[goodboxIndicies, ]
    
    ID <- paste0(row(lat),"_",col(lat))[goodboxIndicies]
    print(paste("Prepared for polygon creation: ",round((proc.time()-pts)[3],1),"sec"))
    # Remove cells with NaN values. Assume lat and long are same
    
    require(maps)
    polys <- SpatialPolygons(
        mapply(
            function(poly, id) {
                xy <- matrix(poly, ncol=2, byrow=TRUE)
                Polygons(list(Polygon(xy)), ID=id)
            }, 
            split(boxes, row(boxes)), ID),
        proj4string=CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs")
    )
    # Trim off the last column and row as these are extensions to
    # create the polygon corners.
    rowData <- as.vector(row(lat))
    colData <- as.vector(col(lat))
    dfLatLong <- data.frame(row=rowData, col=colData)[goodboxIndicies,]
    dfData <- data[goodboxIndicies,]
    dataTable <- cbind(dfData,dfLatLong)
    row.names(dataTable) <- ID
    spp <- SpatialPolygonsDataFrame(polys,data=dataTable)
    print(paste("SpatialPolygonsDataFrame complete: ",round((proc.time()-pts)[3],1),"sec"))
    return(spp)
} 


# Utility function for coordinating the creation of the output shapefile.
createDepthShpFile <- function (outname, ncfile) {
  # Setup outputs, checking if they have already been created
  outdir <- dirname(outname)
  dir.create(outdir, showWarnings = FALSE)
  
  # If the output files already exist then skip regenerating them
  # this is done as each step can take a while. This makes the
  # script more restartable.
  outfile <- paste0(outname,'.shp')
  if (file.exists(outfile)) {
	  print(paste0('Skipping shapefile creation as output already exists: ',outfile))
  } else {
  
    if (!file.exists(ncfile)) {
  	  stop(paste0("NetCDF file not found. See script comments for where to download the input data. ",ncfile))
    }
    
    nc <- nc_open(ncfile)
    varData <- ncvar_get( nc, nc$var$botz, start=c(1,1), count=nc$var$botz$varsize )
    lat <- ncvar_get(nc, 'latitude')
    long <- ncvar_get(nc, 'longitude')
    polys <- toPolygons(lat, long, data.frame(botz=as.vector(varData)))
    
    
    prjStr <-'GEOGCS["GCS_WGS_1984",DATUM["D_WGS_1984",SPHEROID["WGS_1984",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]]'
    cat(prjStr, file=paste0(outname,'.prj'))
    writePolyShape(polys,outname)
    
    print(paste0("Shapefile generated: ",outname,".shp"))

  }
}

outname <- 'export/GBR_AIMS_eReefs-GBR4-hydro-grid_depth'
print('===== Creating GBR 4 grid shapefile ====')
createDepthShpFile(outname, gbr4ncfile)


outname <- 'export/GBR_AIMS_eReefs-GBR1-hydro-grid_depth'
print('===== Creating GBR 1 grid shapefile ====')
createDepthShpFile(outname, gbr1ncfile)


