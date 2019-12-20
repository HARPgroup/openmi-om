source('~/openmi-om/R/utils/fn.climate_evap.and.prcp.R')

batch.climate <- function(outpath) {
  wdm.list <- list.files(path = outpath, pattern = "\\_1000.csv$", recursive = FALSE)
  names.pt1 <- strsplit(wdm.list, "met_")
}