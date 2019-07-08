#' Land Use Unit Flow at Edge of Stream for All Uses Compiler Function 
#' @description Compiles .csv files for all land uses unit flows into one .csv 
#' @param land.segment a string containing the name of a CBP land segment
#' @param wdmpath a string giving the filepath to within the model phase directory
#' @param mod.scenario a string of the model scenario -- ex. "p532cal_062211"
#' @param outpath the location where the output .csv file should be created
#' @return The location of the exported .csv land use unit flow file 
#' @import lubridate
#' @export land.use.eos.all

# DOCUMENTATION ----------
# Daniel Hildebrand
# 6-11-19
# This script generates a single .csv file named "[cbp_scenario][landsegment]_eos_all" containing columns for 
# [luname_suro], [luname_ifwo], [luname_agwo] for all land uses.

# LOADING LIBRARIES ----------
library(lubridate)

land.use.eos.all <- function(land.segment, wdmpath, mod.scenario, outpath) {
  # INPUTS ----------
  land.use.list <- list.dirs(paste0(wdmpath, "/tmp/wdm/land"), full.name = FALSE, recursive = FALSE)
  dsn.list <- data.frame(dsn = c('0111', '0211', '0411'), dsn.label = c('suro', 'ifwo', 'agwo'))
  
  # READING IN LAND USE DATA FROM MODEL ----------
  counter <- 1
  total.files <- as.integer(length(land.use.list)*length(dsn.list$dsn))
  for (i in 1:length(dsn.list$dsn)) {
    for (j in 1:length(land.use.list)) {
      input.data.namer <- paste0(land.segment,land.use.list[j],dsn.list$dsn[i])
      print(paste("Downloading", counter, "of", total.files))
      counter <- counter+1
      temp.data.input <- try(read.csv(paste0(wdmpath, "/tmp/wdm/land/",land.use.list[j],"/",mod.scenario,"/",land.use.list[j],land.segment,"_",dsn.list$dsn[i],".csv")))
      if (class(temp.data.input) == 'try-error') {
        stop(paste0("ERROR: Missing land use .csv files (including ", wdmpath, "/tmp/wdm/land/",land.use.list[j],"/",mod.scenario,"/",land.use.list[j],land.segment,"_",dsn.list$dsn[i],".csv", ")"))
      }
      colnames(temp.data.input) <- c('Year', 'Month', 'Day', 'Hour', as.character(dsn.list$dsn.label[i]))
      temp.data.input$thisdate <- strptime(paste(temp.data.input$Year, "-", temp.data.input$Month, "-", temp.data.input$Day, ":", temp.data.input$Hour, sep = ""), format = "%Y-%m-%d:%H")
      temp.data.formatter <- data.frame(temp.data.input$thisdate, temp.data.input[5])
      colnames(temp.data.formatter) <- c('thisdate', colnames(temp.data.input[5]))
      assign(input.data.namer,temp.data.formatter)
    }
  }
  
  # COMBINING DATA FROM EACH TYPE OF FLOW INTO A SINGLE DATA FRAME ----------
  overall.data.namer <- paste(mod.scenario,land.segment,"eos_all", sep = "_")
  counter <- 1
  for (i in 1:length(land.use.list)) {
    for (j in 1:length(dsn.list$dsn)) {
      input.data.namer <- paste0(land.segment,land.use.list[i],dsn.list$dsn[j])
      temp.data.holder <- get(input.data.namer)
      if (counter == 1) {
        overall.data.builder <- temp.data.holder
        names(overall.data.builder)[2] <- paste(land.use.list[i], colnames(temp.data.holder[2]), sep = "_") 
      } else {
        overall.data.builder[,counter+1] <- temp.data.holder[,2]
        names(overall.data.builder)[names(overall.data.builder) == paste0('V', counter+1)] <- paste(land.use.list[i], colnames(temp.data.holder[2]), sep = '_')
      }
      counter <- counter + 1
    }
  }
  assign(overall.data.namer,overall.data.builder)
  saved.file <- paste0(outpath, "/", overall.data.namer, ".csv")
  write.csv(overall.data.builder, saved.file, row.names = FALSE)
  return(saved.file)
}
