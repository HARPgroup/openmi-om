csv.move.all <- function(csvpath, outputdir) {
  csv.list <- list.files(path = csvpath, pattern = "\\.csv$", recursive = FALSE)
  setwd(csvpath)
  for (i in 1:length(csv.list)) {
    print(paste('Moving', i, 'of', length(csv.list), 'csv files'), sep = ' ')
    csvname <- csv.list[i]
    move.to.outputdir <- paste("mv", csvname, outputdir)
    system(command = move.to.outputdir)
  }
}