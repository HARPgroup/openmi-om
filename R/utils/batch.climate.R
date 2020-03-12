source('~/openmi-om/R/utils/fn.climate_evap.and.prcp.R')

batch.climate <- function(outpath) {
  wdm.list <- list.files(path = outpath, pattern = "_1000\\.csv$", recursive = FALSE)
  names.pt1 <- sapply(strsplit(wdm.list, "met_"), "[[", 2)
  segs <- sapply(strsplit(names.pt1, "_1000.csv"), "[[", 1)
  
  for (i in 1:length(segs)) {
    climate_evap.and.prcp(segment = segs[i], wdmpath = '/opt/model/p6/p6_gb604', outpath = outpath)
    print(paste('creating .csv file', i, 'of', length(segs), sep = ' '))
  }
}