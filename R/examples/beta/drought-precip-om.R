# install.packages('https://github.com/HARPgroup/openmi-om/raw/master/R/openmi.om_0.0.0.9106.tar.gz', repos = NULL, type="source")

library("openmi.om")
library("xts")
library("IHA")
library("lubridate")
library("jsonlite")


#hydro_tools <- 'C:\\usr\\local\\home\\git\\hydro-tools\\'#location of hydro-tools repo
hydro_tools <- 'C:\\Users\\nrf46657\\Desktop\\VAHydro Development\\GitHub\\hydro-tools\\'#location of hydro-tools repo
source(paste(hydro_tools,"VAHydro-2.0","rest_functions.R", sep = "\\")) #load REST functions
source(paste(hydro_tools,"auth.private", sep = "\\"))
token <- rest_token(site, token, rest_uname, rest_pw);


#****************************
# BEGIN Model
#****************************
# instantiate a version of model container: openmi.om.runtimeController
m <- openmi.om.runtimeController();

#****************************
# Set up run timer
#****************************
m$timer$starttime = as.POSIXct('1997-10-01')
m$timer$endtime = as.POSIXct('1999-09-30')
m$timer$thistime = m$timer$starttime
m$timer$dt <- 86400

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
pobs_nova$name = 'Precip Obs NOVA'
pobs_nova$addInput('wyb', wyb, 'value')
pobs_nova$equation = paste(
  "drange = paste(wyb,'-10-01','/',as.character(thistime),sep='')",
  "tsvals <- k$tsvalues[drange]",
  "sum(as.numeric(tsvals$Northern))",
  sep=";"
)
m$addComponent(pobs_nova)

pnml_matrix_nova <- openmi.om.matrix()
pnml_matrix_nova$name = 'Precip Nml NOVA'
pnmp <- getProperty(
  list(
    varkey = 'precip_nml_annual',
    entity_type = 'dh_feature',
    bundle = 'om_data_matrix',
    featureid = 256846
  ),
  base_url,
  prop
)
pnm <- unserializeJSON(pnmp$field_dh_matrix)
names(pnm) <- as.character(unlist(pnm[1,]))
pnm <- pnm[-1,]
rownames(pnm) <- NULL
#for (z in 1:length(pnm)) {
#  pnm[,z] <-as.numeric(as.character(pnm[,z]))
#}
pnml_matrix_nova$datamatrix <- as.matrix(pnm)

pnml_matrix_nova$colindex = 'nml_daily'
# could maybe just refer to the internal "mo"?  But this works too which is cool.
pnml_matrix_nova$addInput('rowindex', mo, 'value')
pnml_matrix_nova$debug = TRUE
m$addComponent(pnml_matrix_nova)

pnml_nova <- openmi.om.equation();
pnml_nova$name = "WY to Date Precip NOVA"
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
pnmp <- getProperty(
  list(
    varkey = 'precip_nml_annual',
    entity_type = 'dh_feature',
    featureid = 256848
  ),
  base_url,
  prop
)
pnm <- unserializeJSON(pnmp$field_dh_matrix)
names(pnm) <- as.character(unlist(pnm[1,]))
pnm <- pnm[-1,]
rownames(pnm) <- NULL
#for (z in 1:length(pnm)) {
#  pnm[,z] <-as.numeric(as.character(pnm[,z]))
#}
pnml_matrix_shen$datamatrix <- as.matrix(pnm)
pnml_matrix_shen$colindex = 'nml_daily'
# could maybe just refer to the internal "mo"?  But this works too which is cool.
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
#logger$directory = "C:/WorkSpace/modeling/projects/potomac/icprb-drought-2018"
logger$directory = getwd()
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
