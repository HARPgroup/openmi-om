wdm.to.csv.all <- function(wdmpath, outputdir, start.year, end.year, dsn) {
  wdm.list <- list.files(path = wdmpath, pattern = "\\.wdm$", recursive = FALSE)
  for (i in 1:length(wdm.list)) {
    quick.wdm.2.txt.inputs <- paste(wdm.list[i], start.year, end.year, dsn, sep = ',')
    run.quick.wdm.2.txt <- paste("echo", quick.wdm.2.txt.inputs, "| /opt/model/p6-devel/p6-4.2018/code/bin/quick_wdm_2_txt_hour_2_hour", sep = ' ')
    system(command = run.quick.wdm.2.txt)
    csvname <- strsplit(wdm.list[i], split = ".wdm")
    csvname <- paste(csvname[[1]], ".csv", sep = '')
    move.to.outputdir <- paste("mv", csvname, outputdir)
  }
}