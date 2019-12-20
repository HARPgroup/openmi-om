#' Compiles evaporation and precipitation data 
#' @description Compiles .csv files for evaporation and precipitation unit flows into one .csv 
#' @param segment a string containing the name of a CBP land segment
#' @param wdmpath a string giving the filepath to within the model phase directory
#' @param outpath the location where the output .csv file should be created
#' @return The location of the exported .csv land use unit flow file 
#' @import lubridate
#' @export climate_evap.and.prcp

# DOCUMENTATION ----------
# Daniel Hildebrand
# 12-20-19
# This script generates a single .csv file named "[segment]_1000-2000" containing columns for 
# [evap] and [precip]

# LOADING LIBRARIES ----------
library(lubridate)

climate_evap.and.prcp <- function(segment, wdmpath, outpath) {
  # INPUTS ----------
  dsn.list <- data.frame(dsn = c('1000', '2000'), dsn.label = c('EVAP', 'PRCP'))
  
  # READING IN AND DELETING READ-IN LAND USE DATA FROM MODEL ----------
  evap.data.namer <- paste0('met_', segment, '_1000.csv')
  prcp.data.namer <- paste0('prad_', segment, '_2000.csv')
  
  evap.data <- try(read.csv(paste0(wdmpath, "/out/climate/",evap.data.namer)))
  if (class(evap.data) == 'try-error') {
    stop(paste0("ERROR: Missing climate .csv files (including ", wdmpath, "/out/climate/",evap.data.namer))
  }
  prcp.data <- try(read.csv(paste0(wdmpath, "/out/climate/",prcp.data.namer)))
  if (class(prcp.data) == 'try-error') {
    stop(paste0("ERROR: Missing climate .csv files (including ", wdmpath, "/out/climate/",prcp.data.namer))
  }
  
  colnames(evap.data) <- c('Year', 'Month', 'Day', 'Hour', 'evap')
  colnames(prcp.data) <- c('Year', 'Month', 'Day', 'Hour', 'prcp')
  
  evap.data$thisdate <- strptime(paste(evap.data$Year, "-", evap.data$Month, "-", evap.data$Day, ":", evap.data$Hour, sep = ""), format = "%Y-%m-%d:%H")

  data.out <- data.frame(evap.data$thisdate, evap.data$evap, prcp.data$prcp)
  colnames(data.out) <- c('thisdate', 'evap', 'prcp')

  # Deleting read in files:
  command <- paste0('rm ', wdmpath, "/out/climate/",evap.data.namer)
  system(command)

  command <- paste0('rm ', wdmpath, "/out/climate/",prcp.data.namer)
  system(command)

  overall.data.namer <- paste0(segment, '_1000-2000')
  saved.file <- paste0(outpath, "/", overall.data.namer, ".csv")
  write.csv(data.out, saved.file, row.names = FALSE)
  return(saved.file)
}
