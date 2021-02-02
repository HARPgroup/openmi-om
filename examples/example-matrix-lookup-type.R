# install.packages('https://github.com/HARPgroup/openmi-om/raw/master/R/openmi.om_0.0.0.9102.tar.gz', repos = NULL, type="source")

library("openmi.om")
# instantiate a version of om.equation
m <- openmi.om.runtimeController();
#****************************
# Set up run timer
#****************************
m$timer$starttime = as.POSIXct('2001-01-01')
m$timer$endtime = as.POSIXct('2001-03-15')
m$timer$thistime = m$timer$starttime
m$timer$dt <- 15 * 86400
#****************************
# Add Basic Equations
#****************************
k <- openmi.om.equation();
k$defaultvalue = 0
k$equation = "value + 0.1"; # just add one to previous value
m$addComponent(k) 
# Matrix
j <- openmi.om.matrix()
mm <- as.matrix(
  rbind(
    c(1, 1.0),
    c(4, 8.0),
    c(6, 12.0),
    c(8, 16.0),
    c(12, 24.0)
  )
)
j$datamatrix <- mm
colnames(j$datamatrix) <- c('mo','val')
j$rowtype = as.integer(2)
j$colindex = 'val'
# @todo: figure out how to get this without using equation
# current month
mo <- openmi.om.equation();
mo$equation = "mo";
m$addComponent(mo) 
j$addInput('rowindex', mo, 'value') 


m$addComponent(j) 

#****************************
# Call initialize for model and all children
#****************************
m$initialize()
#****************************
# Run Model
#****************************
m$run()
