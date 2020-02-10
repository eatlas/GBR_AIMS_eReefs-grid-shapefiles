# Get the element from the matrix. If the index is out of bounds then 
# return NaN.
getElems2 <- function(mat, i, j) {
    results <- matrix(NaN, length(i), length(j))
    # Only copy values where the indices are in bounds
    results[i<nrow(mat)||i>0,j<ncol(mat)||j>0] <- mat[i,j]
    return(results)
}

# Get a single element from a matrix. If the index is out of bounds
# then return NaN. This function is to normalise the interpolation
# of the grid as a result of hitting the edge of the grid with
# and internal area blocked out with NaNs. Using this function
# will make both cases look the same.
# i - rows, j - columns
getElem <- function(mat, i, j) {
    ncols <- ncol(mat)
    nrows <- nrow(mat)
    # If the index is out of bounds of the matrix return NaN
    if (i > nrows || i <= 0 || j > ncols || j <= 0) {
        return (NaN)
    } else {
        return(mat[i,j])
    }
}



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

# This is partly completed code to allow the regridding to work right up to
# the edge of the NaN cells. NcWMS does not appear to do this an so it
# might be unneccessary.
makeCorners2 <- function(midpoints) {
    # Handle if neighbouring are null. These should be handled in
    # the same as edge conditions.
    ncols <- ncol(midPoints)
    nrows <- nrow(midPoints)
    for (i in 1:nrows) {
        for (j in 1:ncols) {
           # When we select data it might:
           # 1. Have data
           # 2. Be off the edge of the grid 
           # 3. Be NaN if it is at an internal edge of a grid with
           #    sections cut out.
           # When there is no data then extrapolate from existing
           # data.
           
           # Build a box around the current point using the surrounding
           # points on the grid.
           # In R having an index out of bounds results in different
           # behaviour depending on if the index is low, high or zero
           # > m[1,3]
           # Error in m[1, 3] : subscript out of bounds
           # > m[1,0]
           # numeric(0)
           # > m[0,0]
           # <0 x 0 matrix>
           # We thus use a help function to normalise this to always
           # returning NaN.
           elem <- getElem(midPoints,i,j)
           # If the element if NaN then we are either at the edge or
           # a part of the grid that has been excluded, either way
           # we will not be generating a polygon for this cell.
           if (!is.nan(elem)) {
                #  a1    a2    a3
                #     o1    o2
                #  a4    a5    a6
                #     o3    o4  
                #  a7    a8    a9
                # If we assume we are grid cell a5 then we want to calculate
                # the corners o1 - o4. Any of a1 - a9 (except a5) might be NaN
                # Although they are more likely to occuring in rows or columns.
                #  NaN   a2    a3
                #     o1    o2
                #  a4    a5    a6
                #     o3    o4  
                #  a7    a8    a9
                # For a corner if neighbouring cells are available then the 
                # position of the corner is the average of all neighbours.
                # If one is missing then
           }
        }
    }
 }



testMakeCorners <- function () {
    x <- matrix(c(0,1,2,3,10,11,12,13,20,21,22,23),nrow=4,ncol=3)
    cx <- makeCorners(x)
    
    x2 <- matrix(c(0,1,2,3,10,11,12,13,20,21,22,23),nrow=4,ncol=3)
    cx2 <- makeCorners(x2)
    
    x2a <- matrix(c(0,1,2,3,NaN,10,11,12,13,NaN,20,21,22,23,NaN,NaN,NaN,NaN,NaN,NaN),nrow=5,ncol=4)
    cx2a <- makeCorners(x2a)
    
    x3 <- matrix(c(0,1,2,3,NaN,10,11,12,13,14,20,21,22,23,24,30,31,32,33,34),nrow=5,ncol=4)
    cx3 <- makeCorners(x3)
    
    #Plot the nan values in the array
    #plot(col(lat),row(lat), col=rgb(is.nan(lat)*1,0,0))
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
    print(paste("Made corners: ",paste(proc.time()-pts, collapse=",")))
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
    print(paste("Prepared for polygon creation: ",paste(proc.time()-pts, collapse=",")))
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
    print(paste("Polygon creation complete: ",proc.time()-pts, collapse=","))
    # Trim off the last column and row as these are extensions to
    # create the polygon corners.
    rowData <- as.vector(row(lat))
    colData <- as.vector(col(lat))
    dfLatLong <- data.frame(row=rowData, col=colData)[goodboxIndicies,]
    dfData <- data[goodboxIndicies,]
    dataTable <- cbind(dfData,dfLatLong)
    row.names(dataTable) <- ID
    print(paste("Data frame prepared: ",proc.time()-pts))
    spp <- SpatialPolygonsDataFrame(polys,data=dataTable)
    print(paste("SpatialPolygonsDataFrame complete: ",paste(proc.time()-pts, collapse=",")))
    return(spp)
} 
    



