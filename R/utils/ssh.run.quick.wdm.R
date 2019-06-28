library(ssh)

# INPUTS TO ALTER
deq2.user <- 'danielh7'
mod.scenario <- 'p532cal_062211'
land.use <- 'afo'

# SETTING UP SYNTAX FOR COMMAND LINE COMMANDS
user.at.deq2 <- paste(deq2.user, '@deq2.bse.vt.edu', sep = '')
wdm.location <- paste('/opt/model/p53/p532c-sova/tmp/wdm/land/', land.use, '/', mod.scenario, sep = '')
cd.to.wdms <- paste('cd ', wdm.location, sep = '')
start.quick.wdm.2.txt <- '/opt/model/p53/p532c-sova/code/bin/quick_wdm_2_txt_hour_2_hour'
response.to.prompt <- "echo -e 'A10001.wdm, 1984, 2005, 111 \n'"
command <- paste(cd.to.wdms, start.quick.wdm.2.txt, response.to.prompt, sep = '; ')

# SSH-ING INTO DEQ2 AND RUNNING COMMANDS
session <- ssh_connect('danielh7@deq2.bse.vt.edu')
ssh_exec_wait(session, command)
ssh_disconnect(session)
