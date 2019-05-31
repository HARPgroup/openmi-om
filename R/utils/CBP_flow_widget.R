# DOCUMENTATION ----------
# First, click on "Session" -> "Set Work Directory" -> "To Source File Location"

# LOADING LIBRARIES ----------
rm(list = ls())
library(lubridate)

# INPUTS ----------
land.segment <- "A51121"
land.use.list <- c('afo','alf','ccn','cex','cfo','cid','cpd','for','hom','hvf','hwm','hyo','hyw','lwm','nal','nex','nhi','nho','nhy','nid','nlo','npa','npd','pas','rcn','rex','rid','rpd','trp','urs')
dsn.list <- c('0111', '0211', '0411')

# READING IN LAND USE DATA FROM MODEL ----------
counter <- 1
total.files <- as.integer(length(land.use.list)*length(dsn.list))
for (i in 1:length(dsn.list)) {
  for (j in 1:length(land.use.list)) {
    input.data.namer <- paste0(land.segment,land.use.list[j],dsn.list[i])
    print(paste("Downloading", counter, "of", total.files))
    counter <-  counter+1
    temp.data.input <- try(read.csv(paste0("http://deq2.bse.vt.edu/p532c-sova/wdm/land/",land.use.list[j],"/p532cal_062211/",land.use.list[j],land.segment,"_",dsn.list[i],".csv")))
    colnames(temp.data.input) <- c('Year', 'Month', 'Day', 'Hour', dsn.list[i])
    assign(input.data.namer,temp.data.input)
  }
}

# COMBINING DATA FROM EACH TYPE OF FLOW INTO A SINGLE DATA FRAME BY LAND USE ----------
for (i in 1:length(land.use.list)) {
  overall.data.namer <- paste0(land.segment,land.use.list[i],"_ALL")
  for (j in 1:length(dsn.list)) {
    input.data.namer <- paste0(land.segment,land.use.list[i],dsn.list[j])
    temp.data.holder <- get(input.data.namer)
    if (j == 1) {
      overall.data.builder <- temp.data.holder
      names(overall.data.builder)[5] <- paste0(colnames(temp.data.holder[5])) 
    } else {
      overall.data.builder[,j+4] <- temp.data.holder[,5]
      names(overall.data.builder)[names(overall.data.builder) == paste0('V', j+4)] <- paste0(colnames(temp.data.holder[5]))
    }
  }
  assign(overall.data.namer,overall.data.builder)
}
 
# READING IN AND INTERPOLATING LOCAL LAND USE TABLE ----------
land.use.table <- read.csv("LandUse.csv")
start.year <- temp.data.holder$Year[1]
end.year <- temp.data.holder$Year[length(temp.data.holder$Year)]
num.land.use <- nrow(land.use.table)
num.year <- end.year - start.year + 1
interp.pts <- colnames(land.use.table)
land.use.interp <- data.frame(matrix(nrow = num.land.use, ncol = num.year + 1))
names.land.use.interp <- c("luname", start.year:end.year)
colnames(land.use.interp) <- names.land.use.interp
land.use.interp$luname <- land.use.table$luname
for (i in 1:num.land.use) {
  temp.y <- land.use.table[i, 2:ncol(land.use.table)]
  temp.interp <- approx(x = c(1984, 1987, 1992, 1997, 2002, 2005), y = temp.y, xout = start.year:end.year)
  land.use.interp[i,2:length(land.use.interp)] <- temp.interp$y
}
for (i in 1:num.land.use) {
  if (land.use.interp$luname[i] %in% land.use.list) {
    tmp.land.use <- land.use.interp[i,]
    tmp.file.name <- paste0(land.segment,land.use.interp$luname[i],'_ALL')
    tmp.data <- get(tmp.file.name)
    tmp.data$Date <- as.Date(paste0(tmp.data$Year,"-",tmp.data$Month, "-", tmp.data$Day))
    tmp.data <- aggregate(tmp.data[,5:(5+length(dsn.list)-1)], by = list(Date = tmp.data$Date), FUN = sum)
    tmp.data$Qout <- NA
    tmp.data$Qunit <- NA
    for (j in 1:num.year) {
      curr.year <- start.year + j - 1
      curr.land.use.interp <- as.numeric(tmp.land.use[j+1])
      rows.in.year <- which(year(tmp.data$Date) == curr.year)
      tmp.data[rows.in.year,-1] <- tmp.data[rows.in.year,-1]*curr.land.use.interp #in acre-inch/ivld (acre-inch/day)
      tmp.data[rows.in.year,-1] <- tmp.data[rows.in.year,-1]/12*43560/24/60/60
      # ivld is day in this data
      # /12 acre-inch/ivld to acre-ft/ivld
      # * 43560 acre-ft/ivld to ft^3/ivld
      # /24 cubic-feet/ivld to cubic-feet/hour
      # /60 cubic-feet/hour to cubic-feet/min
      # /60 cubic-feet/min to cfs
      tmp.data$Qout[rows.in.year] <- tmp.data$`0111`[rows.in.year] + tmp.data$`0211`[rows.in.year] + tmp.data$`0411`[rows.in.year]
      # Qout in cfs
      tmp.data$Qunit[rows.in.year] <- tmp.data$Qout[rows.in.year] / (curr.land.use.interp * 43560)
      # *43560 cfs to acre-feet/second
      # Qunit in feet/second
    }
    write.csv(tmp.data, paste0(tmp.file.name, ".csv"))
  }
}
