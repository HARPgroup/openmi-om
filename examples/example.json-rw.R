# example.json-rw.R
# install.packages('https://github.com/HARPgroup/openmi-om/raw/master/R/openmi.om_0.0.0.9105.tar.gz', repos = NULL, type="source")

library("openmi.om")
library("xts")
library("IHA")
library("lubridate")

# tracks date based stacks of information
ts.jsx <- setRefClass(
  "openmi.om.ts.jsx",
  contains = "openmi.om.timeSeriesInput",
  # Define the logState method in the methods list
  methods = list(
    asJSON = function () {
      #callSuper()
      # expects an input called tsinput to point to a timeseries object
      instanceJSON <- list(balance = balance,ledger  = ledger)
      #instanceJSON
      json <- ""
      add_json(instanceJSON)
      json
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
k <- ts.jsx();
# Create dat by reading tmp_file
#tmp_file <- "http://s3.amazonaws.com/assets.datacamp.com/production/course_1127/datasets/tmp_file.csv"
tmp_file = "http://deq2.bse.vt.edu/files/icprb/potomac_111518_precip_in.tsv"
dat <- read.table(tmp_file, sep="\t", header=TRUE)
# Convert dat into xts
#k$tsvalues <- xts(dat, order.by = as.Date(dat$Date, "%m/%d/%Y"))
k$tsvalues <- xts(dat, order.by = as.POSIXct(dat$Date, format="%m/%d/%Y"))

#kj <- toJSON(k, force = TRUE) # Works but does very litle

# This *would work if we supported the asJSON() method in the class...
kj <- toJSON(k)
jk <- fromJSON(kj)

# jsonlite::serializeJSON(k) # this works but does not yield an instance of the class
