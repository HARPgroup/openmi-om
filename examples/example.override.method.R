# install.packages('https://github.com/HARPgroup/openmi-om/raw/master/R/openmi.om_0.0.0.9101.tar.gz', repos = NULL, type="source")

library("openmi.om")
# instantiate a version of model container: openmi.om.runtimeController
m <- openmi.om.runtimeController();

#****************************
# Override logState() method
#****************************
# Create a New Reference Class based on the base equation class
# Define the logState method in the methods list
verboseEquation <- setRefClass(
  "verboseEquation",
  contains = "openmi.om.equation",
  # Define the logState method in the methods list
  methods = list(
    logState = function () {
      print("Special overridden")
    }
  )
)
#****************************
# Add Basic Equations
#****************************
# now create an instance of the verboseEquation class we've just made
k <- verboseEquation();
k$defaultvalue = 0
k$equation = "value + 0.1"; # just add one to previous value
m$addComponent(k) 

#****************************
# Set up run timer
#****************************
m$timer$starttime = as.POSIXct('2001-01-01')
m$timer$endtime = as.POSIXct('2001-01-15')
m$timer$thistime = m$timer$starttime
m$timer$dt <- 86400
#****************************
# Call initialize for model and all children
#****************************
m$initialize()
#****************************
# Run Model
#****************************
m$run()
