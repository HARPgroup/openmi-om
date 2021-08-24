# install.packages('https://github.com/HARPgroup/openmi-om/raw/master/R/openmi.om_0.0.0.9105.tar.gz', repos = NULL, type="source")

library("openmi.om")
library("xts")
library("IHA")
library("lubridate")
library("rjson")
library("hydrotools")

# Create datasource
ds <- RomDataSource$new("https://deq1.bse.vt.edu/d.dh", 'restws_admin')
ds$get_token()
#****************************
# Import JSON Objects
#****************************
src_json <- 'https://raw.githubusercontent.com/HARPgroup/vahydro/master/data/vahydro-1.0/YP2_6390_6330.json'
# From vahydro
# src_json <- 'http://deq1.bse.vt.edu/d.dh/dh-properties-openmi-json/5031577'
# src_json <- 'http://deq2.bse.vt.edu/d.dh/dh-properties-openmi-json/5031577'
# this *almost* works:
#  src_json_view <- 'https://deq1.bse.vt.edu/d.dh/openmi-om-export-json/5031577'
#  load_txt <- ds$auth_read(src_json_view, "text/json", "")
  # the trouble is that between these two lines we have to manually edit
  # and remove "[]" from the header, and "--------------" from the footer
#  writeLines(as.character(load_txt),'C:/Workspace/tmp/tst_json.txt')
#  load_objects <- fromJSON(file='C:/Workspace/tmp/tst_json.txt')
  #load_objects <- fromJSON(capture.output(writeLines(as.character(load_txt))))

# this works just fine and should be the basis
  src_json_node <- 'https://deq1.bse.vt.edu/d.dh/node/62/4825081'
  src_json_node <- 'https://deq1.bse.vt.edu/d.dh/node/62/5031577'
  load_txt <- ds$auth_read(src_json_node, "text/json", "")
  load_objects <- fromJSON(load_txt)
  #load_objects <- fromJSON(capture.output(writeLines(as.character(load_txt))))



load_objects <- fromJSON(file = src_json)


#****************************
# BEGIN Model
#****************************
#****************************
# instantiate a version of model container: openmi.om.runtimeController
# Set up run timer
#****************************
#
m <- openmi.om.runtimeController$new();
m$timer$starttime = as.POSIXct('1997-10-01')
m$timer$endtime = as.POSIXct('1997-10-31')
m$timer$thistime = m$timer$starttime
m$timer$dt <- 86400

# since the root object is returned embedded in the json we need to extract it
obj_json <- load_objects["0. Lake Anna: Dominion Power"][[1]]
# this *should* be the same as ^ (but it's not) - figure it out...
# obj_json <- load_objects[names(load_objects)[1]]
#obj <- openmi_om_load_single(obj_json)
obj <- openmi_om_load(obj_json)

# finally add this to a simulation engine
m$addComponent(obj)
# add a counter of month
mo_plus_one <- openmi.om.equation$new();
mo_plus_one$equation = "mo + 1";
m$addComponent(mo_plus_one)
# Test the data sharing

# add a counter of month
mo_input <- openmi.om.base$new();
mo_input$addInput('mop1', mo_plus_one, 'value')
m$addComponent(mo_input)
mop_times_ten <- openmi.om.equation$new();
mop_times_ten$equation = "mop1 * 10";
# this won't yet work unless we:
#  a) add mop1 as an explicit input to mop_times_ten
#  b) enable the arData/state sharing of children (which we will do soon)
# this is solution a) where we explicitly connect these.
mop_times_ten$addInput('mop1', mo_plus_one, 'value')
m$addComponent(mop_times_ten)

# we are going to write back the nml_daily values, and accumulated observed values
# so we initialize these fields here --
# @todo: put an explicit loggin class together to handle this
logger <- openmi.om.logger$new();
logger$debug = FALSE;
logger$addInput('mo_plus_one', mo_plus_one, 'value')
logger$addInput('mop_times_ten', mop_times_ten, 'value')

logger$directory = "C:/WorkSpace/tmp/"
logger$filename = "nad-demo.tsv"
logger$path = paste(logger$directory, logger$filename, sep="/" )

m$addComponent(logger)

#****************************
# Call init for model and all children
#****************************
m$init()
#****************************
# Run Model
#****************************
m$run()
#output log file
write.table(logger$outputs,logger$path, sep = "\t")
