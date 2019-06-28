library(ssh)

# INPUTS TO ALTER
deq2.user <- 'danielh7'
mod.scenario <- 'p532cal_062211'
land.use <- 'afo'

# SETTING UP SYNTAX FOR COMMAND LINE COMMANDS
user.at.deq2 <- paste(deq2.user, '@deq2.bse.vt.edu', sep = '')
wdm.location <- paste('/opt/model/p53/p532c-sova/tmp/wdm/land/', land.use, '/', mod.scenario, sep = '')
cd.to.wdms <- paste('cd ', wdm.location, sep = '')
run.quick.wdm.2.txt <- "echo 'afoA10001.wdm, 1984, 2005, 111' | /opt/model/p53/p532c-sova/code/bin/quick_wdm_2_txt_hour_2_hour"
command <- paste(cd.to.wdms, run.quick.wdm.2.txt, sep = '; ')

# SSH-ING INTO DEQ2 AND RUNNING COMMANDS
session <- ssh_connect('danielh7@deq2.bse.vt.edu')
ssh_exec_wait(session, command)
ssh_disconnect(session)
