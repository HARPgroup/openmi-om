# DOCUMENTATION ----------
# First, click on "Session" -> "Set Work Directory" -> "To Source File Location"

# LOADING LIBRARIES ----------
rm(list = ls())
library(lubridate)

# INPUTS ----------
land.segment <- "A51121"
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
    temp.data.input <- try(read.csv(paste0("http://deq2.bse.vt.edu/p532c-sova/wdm/land/",land.use.list[j],"/p532cal_062211/",land.use.list[j],land.segment,"_",dsn.list[i],".csv")))
    colnames(temp.data.input) <- c('Year', 'Month', 'Day', 'Hour', dsn.list[i])
    assign(input.data.namer,temp.data.input)
  }
}

# COMBINING DATA FROM EACH TYPE OF FLOW INTO A SINGLE DATA FRAME BY LAND USE ----------
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
write.csv(overall.data.builder, paste0(overall.data.namer, ".csv"))