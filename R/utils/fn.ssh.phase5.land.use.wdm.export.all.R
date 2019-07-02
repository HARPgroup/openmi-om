library(ssh)

# INPUTS TO ALTER
land.segment <- 'A10003'
wdmpath <- '/opt/model/p53/p532c-sova'
mod.scenario <- 'p532cal_062211'
deq2.user <- 'danielh7'
start.year <- '1984'
end.year <- '2005'

user.at.deq2 <- paste(deq2.user, '@deq2.bse.vt.edu', sep = '')
session <- ssh_connect(user.at.deq2)

ssh.phase5.land.use.wdm.export <- function(land.segment, wdmpath, mod.scenario, start.year, end.year) {
  land.use.list <- c('afo', 'alf', 'ccn', 'cex', 'cfo', 'cid', 'cpd', 'for', 'hom', 'hvf',
                     'hwm', 'hyo', 'hyw', 'lwm', 'nal', 'nex', 'nhi', 'nho', 'nhy', 'nid',
                     'nlo', 'npa', 'npd', 'pas', 'rcn', 'rex', 'rid', 'rpd', 'trp', 'urs')
  # land.use.list <- list.dirs(paste0(wdmpath, "/tmp/wdm/land"), full.name = FALSE, recursive = FALSE)
  dsn.list <- c('111','211','411')
  
  # SETTING UP LOOPS TO GENERATE ALL LAND USE UNIT FLOWS
  counter <- 1
  total.files <- as.integer(length(land.use.list)*length(dsn.list))

  for (i in 1:length(dsn.list)) {
    for (j in 1:length(land.use.list)) {
      wdm.location <- paste(wdmpath, '/tmp/wdm/land/', land.use.list[j], '/', mod.scenario, sep = '')
      wdm.name <- paste0(land.use.list[j],land.segment,'.wdm')
      
      # SETTING UP COMMAND LINE COMMANDS
      cd.to.wdms <- paste('cd ', wdm.location, sep = '')
      quick.wdm.2.txt.inputs <- paste(paste0(land.use.list[j],land.segment,'.wdm'), start.year, end.year, dsn.list[i], sep = ',')
      run.quick.wdm.2.txt <- paste("echo", quick.wdm.2.txt.inputs, "| /opt/model/p53/p532c-sova/code/bin/quick_wdm_2_txt_hour_2_hour", sep = ' ')
      command <- paste(cd.to.wdms, run.quick.wdm.2.txt, sep = '; ')
      
      # RUNNING COMMAND LINE COMMANDS
      print(paste("Creating unit flow .csv for ", counter, "of", total.files))
      counter <- counter+1
      ssh_exec_wait(session, command)
    }
  }
}

ssh_disconnect(session)