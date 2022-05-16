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
channel_storage$equation <- "as.numeric(approx(ftable_matrix$datamatrix[,\"VOLUME\"],ftable_matrix$datamatrix[,\"DISCH\"],50000)$y)"


# susquehana
# Trapezoid
channel_model_trap <- openmi.om.channelObjectSimple$new()
channel_model_rect$channeltype <- 2
channel_model_trap$length <- 68851.2
channel_model_trap$Z <- 1.0
channel_model_trap$base <- 850
channel_model_trap$n <- 0.095
channel_model_trap$slope <- 0.000262014
S_mean <- channel_model_trap$SfQ_lim(800*10^6, 15200.0, 14000.0, 86400)
Qave_1 <- channel_model_trap$QfS(S_mean)$Q
S_1 <- S_0 + (Qave_1 - Qin_1) * dt


channel_model_trap$QfS(53900.0*43559.9)

# below yields approx 16,000 cfs for volume of 800 million cuft
channel_model_trap$QfS(800*10^6)$Q
channel_model_trap$QfS(800*10^6)$V
channel_model_trap$QfS(800*10^6)$A
channel_model_trap$QfS(800*10^6)$d

# Rectangle
channel_model_rect <- openmi.om.channelObjectSimple$new()
channel_model_rect$channeltype <- 1
channel_model_rect$length <- 68851.2
channel_model_rect$Z <- 1.0
channel_model_rect$base <- 850
channel_model_rect$n <- 0.68
channel_model_rect$slope <- 0.000262014
channel_model_rect$SfQ_lim(800*10^6, 15200.0, 14000.0, 86400)
S1 <- channel_model_rect$SfQ_rect_euler(800*10^6, 14000.0, 86400)
channel_model_rect$QfS(S1)

channel_model_trap$QfS(800*10^6)$Q
channel_model_trap$QfS(800*10^6)$V
channel_model_trap$QfS(800*10^6)$A
channel_model_trap$QfS(800*10^6)$d



# OM model
# Flatlick Branch
# runoff element 353071
# Watershed element 353061
# run 201 = 1988-2002
# run 1141 = 1984-2020
fbdat <- om_get_rundata(353061 , 201, site=omsite)
quantile(fbdat$local_channel_its)
Z =	2.1267929833197
drainage_area = 4.22
base = 12.40505107886
length = 14256
n = 0.095
slope = 0.007


# OM model with timestep trouble
mlelid = 340286
mldat <- om_get_rundata(mlelid, 201, site=omsite)

