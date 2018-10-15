# install.packages('https://github.com/HARPgroup/openmi-om/raw/master/R/openmi.om_0.0.0.9100.tar.gz', repos = NULL, type="source")

library("openmi.om")
# instantiate a version of om.equation
m <- openmi.om.runtimeController();

j <- openmi.om.equation();
k <- openmi.om.equation();
l <- openmi.om.equation();
k$defaultvalue = 0
m$addComponent(k) 
m$addComponent(l) 
m$addComponent(j) 
j$debug = FALSE
k$equation = "value + 1"; # just add one to previous value
l$addInput('kval', k, 'value', 'numeric')
l$equation = "kval + 2"
j$addInput('k', k, 'value', 'numeric')
j$addInput('l', l, 'value', 'numeric')
j$equation = "k^2 + l"
m$timer$starttime = as.POSIXct('2001-01-01')
m$timer$endtime = as.POSIXct('2001-01-15')
m$timer$thistime = m$timer$starttime
m$initialize()
j$debug <- TRUE
m$run()
