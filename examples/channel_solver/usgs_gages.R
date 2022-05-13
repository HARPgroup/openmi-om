# Gage options

# 01646305 DEAD RUN AT WHANN AVENUE NEAR MCLEAN, VA
# 9.6 sqkm, 1947-1956, Feb2013-present, has MLLR, hydroid = 58586
usgs_gage_no <- "01646305"

# 01654500 Long Branch Annandale VA
# 9.6 sqkm, 1947-1956, Feb2013-present, has MLLR, hydroid = 58586
usgs_gage_no <- "01654500"
# 01645704 DIFFICULT RUN ABOVE FOX LAKE NEAR FAIRFAX, VA
# 14.2 sqkm, Oct2007-present, no MLLR, hydroid = 58578
usgs_gage_no <- "01645704"
# 01656903 FLATLICK BRANCH ABOVE FROG BRANCH AT CHANTILLY, VA
# 10.9 sqkm, Oct2007-present, no MLLR, hydroid = 58588
usgs_gage_no <- "01656903"

usgs_flow <- dataRetrieval::readNWISdv(usgs_gage_no,'00060')
usgs_flow <- dataRetrieval::readNWISdata(
  sites=usgs_gage_no, service="iv",parameterCd="00060",
  startDate="2007-03-01T00:00Z",endDate="2021-12-31T12:00Z"
)

usgs_flow$month <- month(usgs_flow$Date)
usgs_flow$year <- year(usgs_flow$Date)
usgs_flow$day <- day(usgs_flow$Date)

usgs_flow_df <- as.data.frame(usgs_flow)
sqldf(
  "
   select year, avg(X_00060_00003) as Qmean, count(*)
  from usgs_flow_df
  group by year
  order by year
  "
)


