# install.packages('https://github.com/HARPgroup/openmi-om/raw/master/R/openmi.om_0.0.0.9101.tar.gz', repos = NULL, type="source")

library("openmi.om")
# instantiate a version of om.equation
m <- openmi.om.runtimeController();
#****************************
# Add Basic Equations
#****************************
k <- openmi.om.equation();
k$defaultvalue = 0
k$equation = "value + 0.1"; # just add one to previous value
m$addComponent(k) 
#****************************
# ** Object with Inputs
# Add inputs to the object "l"
# Set equation for object "l"
#****************************
l <- openmi.om.equation();
l$addInput('kval', k, 'value', 'numeric')
l$equation = "kval + 2"
m$addComponent(l) 
#****************************
# Now, add a hypothetical withdrawal
#****************************
w <- openmi.om.equation();
w$equation = "0.2 * flow"
w$addInput('flow', j, 'value', 'numeric')
w$debug = TRUE
m$addComponent(w) 
#****************************
# Now, add a flow
#****************************
q <- openmi.om.equation();
q$addInput('k', k, 'value', 'numeric')
q$equation = "10 * sin(k)"
q$debug = TRUE
j$debug = FALSE
m$addComponent(q) 

#****************************
# Set equation for object "l"
# Add multiple inputs to the object "j"
#****************************
j <- openmi.om.equation();
j$addInput('k', k, 'value', 'numeric')
j$addInput('l', l, 'value', 'numeric')
j$addInput('q', q, 'value', 'numeric')
j$addInput('w', w, 'value', 'numeric')
j$equation = "q - w"
j$debug <- TRUE
m$addComponent(j) 


#****************************
# Set up run timer
#****************************
m$timer$starttime = as.POSIXct('2001-01-01')
m$timer$endtime = as.POSIXct('2001-01-15')
m$timer$thistime = m$timer$starttime
m$timer$dt <- 86400
#****************************
# Call initialize for model and all children
#****************************
m$initialize()
#****************************
# Run Model
#****************************
m$run()
