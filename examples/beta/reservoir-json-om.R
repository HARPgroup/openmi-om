# install.packages('https://github.com/HARPgroup/openmi-om/raw/master/R/openmi.om_0.0.0.9105.tar.gz', repos = NULL, type="source")

library("openmi.om")
library("xts")
library("IHA")
library("lubridate")
library("rjson")
library("hydrotools")


#****************************
# Import JSON Objects
#****************************
src_json <- 'https://raw.githubusercontent.com/HARPgroup/vahydro/master/data/vahydro-1.0/YP2_6390_6330.json'
load_objects <- fromJSON(file = src_json)
model_objects <- names(load_objects)
for (i in index(model_objects)) {
  elemname <- model_objects[i]
  names(load_objects[elemname][[1]])
}
# properties of Lake Anna impoundment:
# names(load_objects["0. Lake Anna: Dominion Power"][[1]])
# sub-properties of whtf_natevap_mgd property
# names(load_objects["0. Lake Anna: Dominion Power"][[1]]["whtf_natevap_mgd"][[1]])

openmi_om_load <- function(elem_list) {
  if (!is.null(elem_list$object_class)) {
    message(paste("Found", elem_list$object_class))
    if (elem_list$object_class == 'Equation') {
      # we got this
      elem_obj <- openmi.om.equation(elem_list)
    } elseif (elem_list$object_class == 'textField') {
      if (!is.null(elem_list$value)) {
        elem_obj <- elem_list$value
      }
    }    else {
      elem_obj <- openmi.om.base()
    }
  }
}


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
m$timer$endtime = as.POSIXct('1999-09-30')
m$timer$thistime = m$timer$starttime
m$timer$dt <- 86400


obj <- load_objects["0. Lake Anna: Dominion Power"][[1]]
m$addComponent(openmi_om_load(obj))

for (j in names(obj)) {
  openmi_om_load(obj[j])
}
#****************************
# Call initialize for model and all children
#****************************
m$init()
#****************************
# Run Model
#****************************
m$run()

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
wyb <- openmi.om.equation();
wyb$equation = "water.year(timer$thistime) - 1";
m$addComponent(wyb)
# current month
mo <- openmi.om.equation();
mo$equation = "mo";
m$addComponent(mo)

#######################################################
# BEGIN - Northern VA REgion
#######################################################
pobs_nova <- openmi.om.equation();
pobs_nova$addInput('wyb', wyb, 'value')
pobs_nova$equation = paste(
  "drange = paste(wyb,'-10-01','/',as.character(thistime),sep='')",
  "tsvals <- k$tsvalues[drange]",
  "sum(as.numeric(tsvals$Northern))",
  sep=";"
)
m$addComponent(pobs_nova)

pnml_matrix_nova <- openmi.om.matrix()
pnml_matrix_nova$datamatrix <- as.matrix(
  vahydro_prop_matrix(
    256846,
    entity_type = 'dh_feature',
    varkey = 'precip_nml_annual',
    datasite = 'http://deq1.bse.vt.edu/d.dh'
  )
);
pnml_matrix_nova$colindex = 'nml_daily'
# could maybe just refer to the internal "mo"?  But this works too which is cool.
pnml_matrix_nova$addInput('rowindex', mo, 'value')
pnml_matrix_nova$debug = TRUE
m$addComponent(pnml_matrix_nova)

pnml_nova <- openmi.om.equation();
pnml_nova$addInput('nml_daily', pnml_matrix_nova, 'value')
pnml_nova$addInput('wyb', wyb, 'value')
pnml_nova$equation = paste(
  "if ((mo == 10) & (da == 1)) { bval = 0.0; } else { bval = value; }",
  "bval + nml_daily",
  sep=";"
)
m$addComponent(pnml_nova)

# Drought status handlers
ppct_nova <- openmi.om.equation();
ppct_nova$addInput('wyb', wyb, 'value')
# @todo: rolling water year accumulationif >0 drought status at 10/1
ppct_nova$addInput('wy_pobs', pobs_nova, 'value')
ppct_nova$addInput('wy_nml', pnml_nova, 'value')
ppct_nova$equation = "100.0 * (wy_pobs / wy_nml)"
m$addComponent(ppct_nova)

# Drought status handlers
pstatus_nova <- openmi.om.equation();
# @todo: handle this with a simple stair-step matrix
pstatus_nova$addInput('wyb', wyb, 'value')
pstatus_nova$addInput('ppct', ppct_nova, 'value')
pstatus_nova$equation = paste(
  "numdays <- as.numeric(timer$thistime - as.POSIXct(paste(wyb,'-10-01',sep='')))",
  "print(paste(numdays, 'days since the wy began'))",
  "pcts = c( 85.0, 75.0, 65.0, 0.0)",
  "if (numdays <= 91) pcts = c(75.0, 65.0, 55.0, 0.0)",
  "if (numdays <= 182) pcts = c(80.0, 70.0, 60.0, 0.0)",
  "if (numdays <= 212) pcts = c(81.5, 71.5, 61.5, 0.0)",
  "if (numdays <= 243) pcts = c(82.5, 72.5, 62.5, 0.0)",
  "if (numdays <= 273) pcts = c(83.5, 73.5, 63.5, 0.0)",
  "print(pcts)",
  "pstatus = which.min(pcts > ppct) - 1",
  "print(ppct)",
  "print(pstatus)",
  "pstatus",
  sep = ";"
)
m$addComponent(pstatus_nova)
# @todo: rolling water year accumulation if >0 drought status at 10/1
#############################################
# END - Northern VA REgion
#############################################


#######################################################
# BEGIN - Shenadoah
#######################################################
pobs_shen <- openmi.om.equation();
pobs_shen$addInput('wyb', wyb, 'value')
pobs_shen$equation = paste(
  "drange = paste(wyb,'-10-01','/',as.character(thistime),sep='')",
  "tsvals <- k$tsvalues[drange]",
  "sum(as.numeric(tsvals$Shenandoah))",
  sep=";"
)
m$addComponent(pobs_shen)

pnml_matrix_shen <- openmi.om.matrix()
pnml_matrix_shen$datamatrix <- as.matrix(
  vahydro_prop_matrix(
    256848,
    entity_type = 'dh_feature',
    varkey = 'precip_nml_annual',
    datasite = 'http://deq1.bse.vt.edu/d.dh'
  )
);
pnml_matrix_shen$colindex = 'nml_daily'
# could maybe just refer to the internal "mo"?
#   - But this works too which is cool.
pnml_matrix_shen$addInput('rowindex', mo, 'value')
pnml_matrix_shen$debug = TRUE
m$addComponent(pnml_matrix_shen)

pnml_shen <- openmi.om.equation();
pnml_shen$addInput('nml_daily', pnml_matrix_shen, 'value')
pnml_shen$addInput('wyb', wyb, 'value')
pnml_shen$equation = paste(
  "if ((mo == 10) & (da == 1)) { bval = 0.0; } else { bval = value; }",
  "bval + nml_daily",
  sep=";"
)
m$addComponent(pnml_shen)

# Drought status handlers
ppct_shen <- openmi.om.equation();
ppct_shen$addInput('wyb', wyb, 'value')
# @todo: rolling water year accumulationif >0 drought status at 10/1
ppct_shen$addInput('wy_pobs', pobs_shen, 'value')
ppct_shen$addInput('wy_nml', pnml_shen, 'value')
ppct_shen$equation = "100.0 * (wy_pobs / wy_nml)"
m$addComponent(ppct_shen)

# Drought status handlers
pstatus_shen <- openmi.om.equation();
# @todo: handle this with a simple stair-step matrix
pstatus_shen$addInput('wyb', wyb, 'value')
pstatus_shen$addInput('ppct', ppct_shen, 'value')
pstatus_shen$equation = paste(
  "numdays <- as.numeric(timer$thistime - as.POSIXct(paste(wyb,'-10-01',sep='')))",
  "print(paste(numdays, 'days since the wy began'))",
  "pcts = c( 85.0, 75.0, 65.0, 0.0)",
  "if (numdays <= 91) pcts = c(75.0, 65.0, 55.0, 0.0)",
  "if (numdays <= 182) pcts = c(80.0, 70.0, 60.0, 0.0)",
  "if (numdays <= 212) pcts = c(81.5, 71.5, 61.5, 0.0)",
  "if (numdays <= 243) pcts = c(82.5, 72.5, 62.5, 0.0)",
  "if (numdays <= 273) pcts = c(83.5, 73.5, 63.5, 0.0)",
  "print(pcts)",
  "pstatus = which.min(pcts > ppct) - 1",
  "print(ppct)",
  "print(pstatus)",
  "pstatus",
  sep = ";"
)
m$addComponent(pstatus_shen)
# @todo: rolling water year accumulation if >0 drought status at 10/1
#############################################
# END - Shenadoah
#############################################


# we are going to write back the nml_daily values, and accumulated observed values
# so we initialize these fields here --
# @todo: put an explicit loggin class together to handle this
logger <- openmi.om.logger();
logger$debug = FALSE;
logger$addInput('wyprecip_nml_nova', pnml_nova, 'value')
logger$addInput('wyprecip_obs_nova', pobs_nova, 'value')
logger$addInput('precip_nml_nova', pnml_matrix_nova, 'value')
logger$addInput('precip_obs_nova', k, 'Northern')
logger$addInput('ppct_nova', ppct_nova, 'value')
logger$addInput('pstatus_nova', pstatus_nova, 'value')
logger$addInput('wyprecip_nml_shen', pnml_shen, 'value')
logger$addInput('wyprecip_obs_shen', pobs_shen, 'value')
logger$addInput('precip_nml_shen', pnml_matrix_shen, 'value')
logger$addInput('precip_obs_shen', k, 'Shenandoah')
logger$addInput('ppct_shen', ppct_shen, 'value')
logger$addInput('pstatus_shen', pstatus_shen, 'value')
logger$directory = "C:/WorkSpace/modeling/projects/potomac/icprb-drought-2018"
logger$filename = "vahydro-precip-drought_v01.tsv"
logger$path = paste(logger$directory, logger$filename, sep="/" )

m$addComponent(logger)

#****************************
# Call initialize for model and all children
#****************************
m$initialize()
#****************************
# Run Model
#****************************
m$run()
#output log file
write.table(logger$outputs,logger$path, sep = "\t")
