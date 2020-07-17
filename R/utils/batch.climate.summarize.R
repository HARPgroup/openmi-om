batch.climate.summarize <- function(dirpath) {
  csv.list <- list.files(path = dirpath, pattern = "_1000-2000\\.csv$", recursive = FALSE)
  
  evap.prcp.table <- data.frame(matrix(data = NA, nrow = length(csv.list), ncol = 7))
  colnames(evap.prcp.table) = c('segment', 'evap.mean', 'prcp.mean', 'evap.l30', 'prcp.l30', 'evap.l90', 'prcp.l90')
  for (i in 1:length(csv.list)) {
    data <- try(read.csv(paste(dirpath, csv.list[i], sep = '/')))
    trim <- which(as.Date(data$thisdate) >= as.Date('1991-01-01') & as.Date(data$thisdate) <= as.Date('2000-12-31'))
    data <- data[trim,]
    
    print(paste('Downloading data for segment', i, 'of', length(csv.list), sep = ' '))
    
    segment <- substr(csv.list[i], 1, 6)
    
    if (class(data) == 'try-error') {
      stop(paste0("ERROR: Missing climate .csv files (including ", dirpath, "/", csv.list[i]))
    }
    
    evap.prcp.table$segment[i] <- segment
    evap.prcp.table$evap.mean[i] <- mean(as.numeric(data$evap))
    evap.prcp.table$prcp.mean[i] <- mean(as.numeric(data$prcp))
    
    data.evap <- aggregate(evap ~ as.Date(thisdate), data, FUN = sum)
    colnames(data.evap) <- c('date', 'flow')
    data.prcp <- aggregate(prcp ~ as.Date(thisdate), data, FUN = sum)
    colnames(data.prcp) <- c('date', 'flow')
    
    evap.prcp.table$evap.l30[i] <- num_day_min(data.evap, num.day = 30, min_or_med = "min")
    evap.prcp.table$prcp.l30[i] <- num_day_min(data.prcp, num.day = 30, min_or_med = "min")
    evap.prcp.table$evap.l90[i] <- num_day_min(data.evap, num.day = 90, min_or_med = "min")
    evap.prcp.table$prcp.l90[i] <- num_day_min(data.prcp, num.day = 90, min_or_med = "min")
    
  }
  
  write.csv(evap.prcp.table, paste(dirpath, 'evap.prcp.table.csv', sep = '/'))
}