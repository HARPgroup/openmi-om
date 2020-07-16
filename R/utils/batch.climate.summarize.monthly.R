library(lubridate)

batch.climate.summarize.monthly <- function(dirpath) {
  csv.list <- list.files(path = dirpath, pattern = "_1000-2000\\.csv$", recursive = FALSE)
  
  for (i in 1:length(csv.list)) {
    print(paste('Downloading data for segment', i, 'of', length(csv.list), sep = ' '))
    
    data <- try(read.csv(paste(dirpath, csv.list[i], sep = '/')))
    trim <- which(as.Date(data$thisdate) >= as.Date('1991-01-01') & as.Date(data$thisdate) <= as.Date('2000-12-31'))
    data <- data[trim,]
    
    segment <- substr(csv.list[i], 1, 6)
    
    if (class(data) == 'try-error') {
      stop(paste0("ERROR: Missing climate .csv files (including ", dirpath, "/", csv.list[i]))
    }
    
    evap.prcp.table <- data.frame(matrix(data = NA, nrow = 13, ncol = 7))
    colnames(evap.prcp.table) = c('month', 'evap.mean', 'evap.med', 'evap.var', 
                                  'prcp.mean', 'prcp.med', 'prcp.var')
    
    evap.prcp.table$month <- c('Overall', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                               'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec')
    
    evap.prcp.table$evap.mean[1] <- signif(mean(as.numeric(data$evap)), 3)
    evap.prcp.table$evap.med[1] <- signif(median(as.numeric(data$evap)), 3)
    evap.prcp.table$evap.var[1] <- signif(var(as.numeric(data$evap)), 3)
    evap.prcp.table$prcp.mean[1] <- signif(mean(as.numeric(data$prcp)), 3)
    evap.prcp.table$prcp.med[1] <- signif(median(as.numeric(data$prcp)), 3)
    evap.prcp.table$prcp.var[1] <- signif(var(as.numeric(data$prcp)), 3)
    
    for (j in 1:12) {
      trim.dat <- data[which(month(as.Date(data$thisdate)) == j),]
      evap.prcp.table$evap.mean[j+1] <- signif(mean(as.numeric(trim.dat$evap)), 3)
      evap.prcp.table$evap.med[j+1] <- signif(median(as.numeric(trim.dat$evap)), 3)
      evap.prcp.table$evap.var[j+1] <- signif(var(as.numeric(trim.dat$evap)), 3)
      evap.prcp.table$prcp.mean[j+1] <- signif(mean(as.numeric(trim.dat$prcp)), 3)
      evap.prcp.table$prcp.med[j+1] <- signif(median(as.numeric(trim.dat$prcp)), 3)
      evap.prcp.table$prcp.var[j+1] <- signif(var(as.numeric(trim.dat$prcp)), 3)
    }
    
    write.csv(evap.prcp.table, paste(dirpath, '/', segment, '_evap.prcp.monthly.summary.csv', sep = ''))
  }
}