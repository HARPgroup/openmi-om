library("openmi.om")
library("stats")
library("dataRetrieval")
# time series of:
# - SU8_1530_1760_FLOW_I.prn: total inflows to river segment
#   has 6 cols: name (FLOW), year, month, day, hour, Qavg (into reach)
# -

# Gage data for Long Branch Annandale VA
usgs_gage_no <- "01654500" # 9.6 sqkm, 1947-1956, Feb2013-present, has MLLR, hydroid =
# 01645704 DIFFICULT RUN ABOVE FOX LAKE NEAR FAIRFAX, VA
# 14.2 sqkm, Oct2007-present, no MLLR, hydroid =
usgs_gage_no <- "01645704"

usgs_flow <- dataRetrieval::readNWISdv(usgs_gage_no,'00060')
usgs_flow$month <- month(usgs_flow$Date)
usgs_flow$year <- year(usgs_flow$Date)
usgs_flow$day <- day(usgs_flow$Date)

usgs_flow_df <- as.data.frame(usgs_flow)
sqldf(
  "
   select year, count(*)
  from usgs_flow_df
  group by year
  order by year
  "
)

river_inflow <- read.table(
  "/usr/local/home/git/openmi-om/examples/channel_solver/SU8_1530_1760_FLOW_I.prn",
  header = TRUE
)
river_ftable <- read.table(
  "/usr/local/home/git/openmi-om/examples/channel_solver/SU8_1530_1760.ftable",
  header = TRUE
)

# rename
names(river_inflow) <- c('FLOW', 'year', 'month', 'day', 'hour', 'Qin')


ftable_matrix <- openmi.om.matrix$new()
ftable_matrix$datamatrix <- as.matrix(
  river_ftable
)

ftable_matrix$colindex = 'nml_daily'
# could maybe just refer to the internal "mo"?  But this works too which is cool.
ftable_matrix$addInput('rowindex', mo, 'value')
ftable_matrix$debug = TRUE


# todo: this is just a shell, but does not yet function so we will use equation for now
#channel_model <- openmi.om.channelObject$new()
channel_model <- openmi.om.equation$new()
channel_model$addComponent(ftable_matrix)
# Storage
channel_storage <- openmi.om.equation$new()
channel_storage$addInput()
channel_storage$equation <- "as.numeric(approx(ftable_matrix$datamatrix[,"VOLUME"],ftable_matrix$datamatrix[,"DISCH"],50000)$y)"


channel_model2 <- openmi.om.channelObjectSimple$new()
channel_model2$length <- 30000
channel_model2$Z <- 1.0
channel_model2$base <- 25.0
channel_model2$n <- 0.05

channel_model2$SfQest(100.0, 86400)
channel_model2$QfS(4320000)
