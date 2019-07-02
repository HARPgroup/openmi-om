# INPUTS TO ALTER
# land.segment <- 'A10003'
# wdmpath <- '/opt/model/p53/p532c-sova'
# mod.scenario <- 'p532cal_062211'
# start.year <- '1984'
# end.year <- '2005'

land.use.wdm.export.all <- function(land.segment, wdmpath, mod.scenario, start.year, end.year) {
  # land.use.list <- c('afo', 'alf', 'ccn', 'cex', 'cfo', 'cid', 'cpd', 'for', 'hom', 'hvf',
  #                    'hwm', 'hyo', 'hyw', 'lwm', 'nal', 'nex', 'nhi', 'nho', 'nhy', 'nid',
  #                    'nlo', 'npa', 'npd', 'pas', 'rcn', 'rex', 'rid', 'rpd', 'trp', 'urs')
  land.use.list <- list.dirs(paste0(wdmpath, "/tmp/wdm/land"), full.name = FALSE, recursive = FALSE)
  dsn.list <- c('111','211','411')
  
  # SETTING UP LOOPS TO GENERATE ALL LAND USE UNIT FLOWS
  counter <- 1
  total.files <- as.integer(length(land.use.list)*length(dsn.list))

  for (i in 1:length(dsn.list)) {
    for (j in 1:length(land.use.list)) {
      wdm.location <- paste(wdmpath, '/tmp/wdm/land/', land.use.list[j], '/', mod.scenario, sep = '')
      wdm.name <- paste0(land.use.list[j],land.segment,'.wdm')
      
      # SETTING UP AND RUNNING COMMAND LINE COMMANDS
      setwd(wdm.location)
      # cd.to.wdms <- paste('cd ', wdm.location, sep = '')
      # exec_wait(cmd = cd.to.wdms)
      
      print(paste("Creating unit flow .csv for ", counter, "of", total.files))
      
      quick.wdm.2.txt.inputs <- paste(paste0(land.use.list[j],land.segment,'.wdm'), start.year, end.year, dsn.list[i], sep = ',')
      run.quick.wdm.2.txt <- paste("echo", quick.wdm.2.txt.inputs, "| /opt/model/p6-devel/p6-4.2018/code/bin/quick_wdm_2_txt_hour_2_hour", sep = ' ')
      system(command = run.quick.wdm.2.txt)
      
      # INCREMENTING COUNTER
      counter <- counter+1
    }
  }
}