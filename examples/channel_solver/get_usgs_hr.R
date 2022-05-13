
library("dataRetrieval")
usgs_gage_no <- "01656903"
usgs_flow <- dataRetrieval::readNWISdata(
  sites=usgs_gage_no, service="iv",parameterCd="00060",
  startDate="2007-01-01T00:00Z",endDate="2021-12-31T12:00Z"
)
write.table(as.data.frame(usgs_flow),paste0(usgs_gage_no,"_hourly.txt"));

