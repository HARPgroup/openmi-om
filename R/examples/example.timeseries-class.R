# install.packages('https://github.com/HARPgroup/openmi-om/raw/master/R/openmi.om_0.0.0.9105.tar.gz', repos = NULL, type="source")

library("openmi.om")
library("xts")
library("IHA")

#****************************
# Override logState() method
#****************************
# tracks date based stacks of information
ts.stack <- setRefClass(
  "openmi.om.ts.stack",
  fields = list(
    stackvals = "ANY",
    intmethod = "integer",
    intflag = "integer"
  ),
  contains = "openmi.om.linkableComponent",
  # Define the logState method in the methods list
  methods = list(
    update = function () {
      callSuper()
      # expects an input called tsinput to point to a timeseries object
      if (is.null(inputs['tsinput'])) {
        return;
      }
      # Do we need to update the limiting dates?
      # shift dates no longer tracked off the stack
      range <<- tsinput[paste(starting,ending, sep="/")]
    }
  )
)


#****************************
# BEGIN Model
#****************************
# instantiate a version of model container: openmi.om.runtimeController
m <- openmi.om.runtimeController();

#****************************
# Add Basic Equations
#****************************
# now create an instance of the verboseEquation class we've just made
k <- openmi.om.timeSeriesInput();
# Create dat by reading tmp_file
#tmp_file <- "http://s3.amazonaws.com/assets.datacamp.com/production/course_1127/datasets/tmp_file.csv"
tmp_file = "http://deq2.bse.vt.edu/files/icprb/potomac_111518_precip_in.tsv"
dat <- read.table(tmp_file, sep="\t", header=TRUE)
# Convert dat into xts
#k$tsvalues <- xts(dat, order.by = as.Date(dat$Date, "%m/%d/%Y"))
k$tsvalues <- xts(dat, order.by = as.POSIXct(dat$Date, format="%m/%d/%Y"))

# add 1 water year stack and a 2 water year to date stacks
# 1 water year obsered, 1 water year normal
# 2 water year observed, 2 water year normal
m$addComponent(k) 

#################################
# Add debugging equation
#################################
j <- openmi.om.equation();
j$data['testslot'] = 100;
j$equation = paste(
  "wyb <- water.year(timer$thistime) - 1",
  "drange = paste(wyb,'-10-01','/',as.character(timer$thistime),sep='')",
  "tsvals <- k$tsvalues[drange]",
  "print(data['testslot'])",
  "sum(as.numeric(tsvals$Northern))",
  sep=";"
)

vahydro_prop_matrix

m$addComponent(j) 

#****************************
# Set up run timer
#****************************
m$timer$starttime = as.POSIXct('1999-01-01')
m$timer$endtime = as.POSIXct('1999-01-15')
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
