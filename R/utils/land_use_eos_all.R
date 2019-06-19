# DOCUMENTATION ----------
# Daniel Hildebrand
# 6-11-19
# This script generates a single .csv file named "[cbp_scenario][landsegment]_eos_all" containing columns for 
# [luname_111], [luname_211], [luname_411] for all land uses.

# LOADING LIBRARIES ----------
rm(list = ls())
library(lubridate)
library(rstudioapi)

# Setting working directory to the source file location
# current_path <- rstudioapi::getActiveDocumentContext()$path 
# setwd(dirname(current_path))

# Setting up output location
# split.location <- strsplit(current_path, split = '/')
# split.location <- as.vector(split.location[[1]])
# basepath.stop <- as.numeric(which(split.location == 'GitHub'))
# basepath <- paste0(split.location[1:basepath.stop], collapse = "/")
output.location <- '/opt/model/p6/p6_gb604/out'

# INPUTS ----------
land.segment <- "A51121"
mod.phase <- "p532c-sova"
mod.scenario <- "p532cal_062211"
land.use.list <- c('afo','alf','ccn','cex','cfo','cid','cpd','for','hom','hvf','hwm','hyo','hyw','lwm','nal','nex','nhi','nho','nhy','nid','nlo','npa','npd','pas','rcn','rex','rid','rpd','trp','urs')
dsn.list <- c('0111', '0211', '0411')

# READING IN LAND USE DATA FROM MODEL ----------
counter <- 1
total.files <- as.integer(length(land.use.list)*length(dsn.list))
for (i in 1:length(dsn.list)) {
  for (j in 1:length(land.use.list)) {
    input.data.namer <- paste0(land.segment,land.use.list[j],dsn.list[i])
    print(paste("Downloading", counter, "of", total.files))
    counter <- counter+1
    temp.data.input <- try(read.csv(paste0("http://deq2.bse.vt.edu/", mod.phase, "/wdm/land/",land.use.list[j],"/",mod.scenario,"/",land.use.list[j],land.segment,"_",dsn.list[i],".csv")))
    colnames(temp.data.input) <- c('Year', 'Month', 'Day', 'Hour', dsn.list[i])
    assign(input.data.namer,temp.data.input)
  }
}

# COMBINING DATA FROM EACH TYPE OF FLOW INTO A SINGLE DATA FRAME ----------
overall.data.namer <- paste(mod.scenario,land.segment,"eos_all", sep = "_")
counter <- 1
for (i in 1:length(land.use.list)) {
  for (j in 1:length(dsn.list)) {
    input.data.namer <- paste0(land.segment,land.use.list[i],dsn.list[j])
    temp.data.holder <- get(input.data.namer)
    if (counter == 1) {
      overall.data.builder <- temp.data.holder
      names(overall.data.builder)[5] <- paste(land.use.list[i], colnames(temp.data.holder[5]), sep = "_") 
    } else {
      overall.data.builder[,counter+4] <- temp.data.holder[,5]
      names(overall.data.builder)[names(overall.data.builder) == paste0('V', counter+4)] <- paste(land.use.list[i], colnames(temp.data.holder[5]), sep = '_')
    }
    counter <- counter + 1
  }
}
assign(overall.data.namer,overall.data.builder)
write.csv(overall.data.builder, paste0(output.location, "/", overall.data.namer, ".csv"))
