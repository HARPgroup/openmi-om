batch.climate.summarize <- function(dirpath) {
  csv.list <- list.files(path = dirpath, pattern = "_1000-2000\\.csv$", recursive = FALSE)
  
  evap.prcp.table <- data.frame(matrix(data = NA, nrow = length(csv.list), ncol = 3))
  colnames(evap.prcp.table) = c('segment', 'evap.mean', 'prcp.mean')
  for (i in 1:length(csv.list)) {
    data <- try(read.csv(paste0(dirpath, csv.list[i], sep = '/')))
    
    segment <- substr(csv.list[i], 1, 6)
    
    if (class(data) == 'try-error') {
      stop(paste0("ERROR: Missing climate .csv files (including ", dirpath, "/", csv.list[i]))
    }
    
    evap.prcp.table$segment[i] <- segment
    evap.prcp.table$evap.mean[i] <- mean(as.numeric(data$evap))
    evap.prcp.table$prcp.mean[i] <- mean(as.numeric(data$prcp))
  }
  
  write.csv(evap.prcp.table, paste0(dirpath, 'evap.prcp.table'))
}