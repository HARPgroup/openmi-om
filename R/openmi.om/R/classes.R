## OpenMI Object-oriented Meta-model classes basic implementation
library(lubridate)

#' The base time-keeping class for simulation control.
#'
#' @param
#' @return reference class of type openmi.om.timer
#' @seealso
#' @export openmi.om.timer
#' @examples
openmi.om.timer <- setRefClass(
  "openmi.om.timer",
  fields = list(
    starttime = "POSIXct",
    endtime = "POSIXct",
    thistime = "POSIXct",
    status = "character",
    mo = "integer",
    da = "integer",
    yr = "integer",
    tz = "integer",
    dt = "numeric" # time step increment in seconds
  ),
  methods = list(
    update = function() {
      if (length(thistime) == 0) {
        thistime <<- starttime
        status <<- 'running'
      }
      thistime <<- thistime + seconds(dt)
      mo <<- as.integer(format(k$timer$thistime,'%m'))
      da <<- as.integer(format(k$timer$thistime,'%d'))
      yr <<- as.integer(format(k$timer$thistime,'%Y'))
      if (thistime > endtime) {
        status <<- 'finished'
      }
    },
    initialize = function() {
      if (length(dt) == 0) {
        dt <<- 86400
      }
      mo <<- as.integer(format(k$timer$thistime,'%m'))
      da <<- as.integer(format(k$timer$thistime,'%d'))
      yr <<- as.integer(format(k$timer$thistime,'%Y'))
      status <<- 'initialized'
    }
  )
)


#' The base object class for meta-model components.
#'
#' @param
#' @return reference class of type openmi.om.base.
#' @seealso
#' @export openmi.om.base
#' @examples
openmi.om.base <- setRefClass(
  "openmi.om.base",
  fields = list(
    name = "character",
    debug = "logical",
    value = "numeric",
    data = "list",
    inputs = "list",
    components = "list",
    host = 'character',
    type = 'character',
    compid = 'character',
    timer = "openmi.om.timer",
    id = 'character'
  ),
  methods = list(
    initialize = function(){
      if (length(debug) == 0) {
        debug <<- FALSE
      }
      # init() in OM php
      if (length(components) > 0) {
        for (i in 1:length(components)) {
          components[[i]]$initialize()
        }
      }
    },
    prepare = function(){
      # preStep() in OM php
      getInputs()
    },
    update = function(){
      # step() in OM php
      prepare()
      if (length(components) > 0) {
        for (i in 1:length(components)) {
          components[[i]]$update()
        }
      }
      finish()
      logState()
    },
    finish = function(){
      # postStep() in OM php
      if (length(components) > 0) {
        for (i in 1:length(components)) {
          components[[i]]$finish()
        }
      }
    },
    validate = function(){

    },
    logState = function () {
      # logState() in OM php

    },
    getValue = function(name = "value"){
      # returns the value.  Defaults to simple case where object only has one possible value
      return(value)
    },
    addInput = function(
      local_name = character(),
      object = openmi.om.base,
      remote_name = '',
      input_type = 'numeric'
    ){
      # adds inputs named as "localname"
      # a given localname input may have multiple inputs
      # so they are stored as a nested list
      if (is.null(inputs[[local_name]])) {
        inputs[[local_name]] <<- list()
        print(paste("adding", local_name, inputs[local_name]))
      }
      iid = length(inputs[[local_name]]) + 1
      inputs[[local_name]][iid] <<- list(
        input = list(
          local_name = local_name,
          object = object,
          remote_name = remote_name,
          input_type = input_type
        )
      )
    },
    # added to base specification
    getInputs = function () {
      # get data from related objects or internal timeseries feeds
      # @todo: determine if we should clear data array at time begin
      # store in internal "data" list
      data$mo <<- timer$mo
      data$da <<- timer$da
      data$yr <<- timer$yr
      data$thistime <<- timer$thistime
      if (length(names(inputs)) > 0) {
        nms = names(inputs)
        for (i in 1:length(nms)) {
          i_name = nms[i]
          for (j in 1:length(inputs[i_name])) {
            input = inputs[[i_name]][[j]]
            #print(input)
            i_object = input$object
            r_name = input$remote_name
            i_type = input$input_type
            if (length(r_name) > 0) {
              i_value = i_object$getValue(r_name)
            } else {
              i_value = i_object$getValue()
            }
            if (i_type == 'numeric') {
              if (j == 1) {
                # nullify on initial
                data[i_name] <<- 0
              }
              data[i_name] <<- data[[i_name]] + as.numeric(i_value)
              #data[i_name] <<- i_value
              if (debug) {
                print(paste("obtained and converted input", i_name, i_value,sep='='))
              }
            }
          }
        }
      }
    },
    logState = function () {

    },
    addComponent = function (thiscomp = openmi.om.base) {
      if (length(thiscomp$host) == 0) {
        thiscomp$host = 'localhost'
      }
      if (length(thiscomp$type) == 0) {
        thiscomp$type = 'unknown'
      }
      if (length(thiscomp$id) == 0) {
        thiscomp$id = paste('local', length(components) + 1, sep='');
      }
      thiscomp$compid = paste(thiscomp$host,thiscomp$type,thiscomp$id, sep=":")
      # we can add this with numberic indices if we like
      # however, we must have a way of linking objects, which
      # requires a persistent name, i.e. a sort of DOI
      # format: host:type:id, examples:
      #   localhost:feature:647 (well 647),
      #   localhost:component:1991 (the withdrawal amt)
      # Input/Link format:
      #   localname:host:type:id:[remote name]
      #   - if property name is null then just use getValue() without parameter
      #print(thiscomp$compid)
      thiscomp$timer = timer
      components[thiscomp$compid] <<- list('object' = thiscomp)
    },
    orderOperations = function () {
      # sets basic hierarchy of execution by re-ordering the components list
    }
  )
)


#' The base class for meta-model simulation control.
#'
#' @param
#' @return reference class of type openmi.om.runtimeController
#' @seealso
#' @export openmi.om.runtimeController
#' @examples
openmi.om.runtimeController <- setRefClass(
  "openmi.om.runtimeController",
  fields = list(
    code = "character"
  ),
  contains = "openmi.om.base",
  methods = list(
    checkRunVars = function() {
      if (!is.null(timer)) {
        if (is.null(timer$starttime)) {
          print("Timer$starttime required. Exiting.")
          return(FALSE)
        } else {
          if (is.null(timer$endtime)) {
            print("Timer$endtime required. Exiting.")
            return(FALSE)
          }
        }
      } else {
        print("Timer object is not set. Exiting.")
        return(FALSE)
      }
      return(TRUE)
    },
    run = function() {
      runok = checkRunVars()
      if (runok) {
        while (timer$status != 'finished') {
          print(paste("Model update() @", timer$thistime,sep=""))
          update()
        }
        print("Run completed.")
      } else {
        print("Could not complete run.")
      }
    },
    update = function() {
      callSuper()
      # Update the timer afterwards
      timer$update()
    },
    initialize = function() {
      callSuper()
      timer$initialize()
    }
  )
)


#****************************
# Override logState() method and has write method on finish()
#****************************
# tracks date based stacks of information
openmi.om.logger <- setRefClass(
  "openmi.om.logger",
  fields = list(
    directory = "character",
    path = "character",
    filename = "character",
    outputs = "ANY"
  ),
  contains = "openmi.om.linkableComponent",
  # Define the logState method in the methods list
  methods = list(
    update = function () {
      callSuper()
    },
    initialize = function () {
      callSuper()
    },
    logState = function () {
      callSuper()
      if (!is.xts(outputs)) {
        # first time, we need to initialize our data columns which includes timestamp
        # @todo: be more parsimonius?
        outputs <<- xts(data.frame(data), order.by = as.POSIXct(data$thistime))
      } else {
        outputs <<- rbind(outputs, xts(data.frame(data), order.by = as.POSIXct(data$thistime)))
      }
    }
  )
)

#' The base class for linkable meta-model components.
#'
#' @param
#' @return reference class of type openmi.om.linkableComponent
#' @seealso
#' @export openmi.om.linkableComponent
#' @examples
openmi.om.linkableComponent <- setRefClass(
  "openmi.om.linkableComponent",
  fields = list(
    value = "numeric",
    code = "character"
  ),
  contains = "openmi.om.base"
)

#' The base class for executable equation based meta-model components.
#'
#' @param
#' @return reference class of type openmi.om.equation
#' @seealso
#' @export openmi.om.equation
#' @examples
openmi.om.equation <- setRefClass(
  "openmi.om.equation",
  fields = list(
    equation = "character",
    eq = "expression",
    defaultvalue = "numeric"
  ),
  contains = "openmi.om.linkableComponent",
  methods = list(
    initialize = function() {
      callSuper()
      if (length(defaultvalue) == 0) {
        defaultvalue <<- 0
      }
      value <<- defaultvalue
      eq <<- parse(text=equation)
    },
    update = function() {
      callSuper()
      # evaluating an equation should be:
      # 1. restricted to variables in the local $data array
      # step() in OM php
      data$value <<- value
      preval = eval(eq, data)
      value <<- as.numeric(preval)
      if (debug) {
        print(paste("eq = ", equation, " value = ", value))
      }
    }
  )
)


#' The base class for timeseries meta-model components.
#'
#' @param
#' @return reference class of type openmi.om.timeSeriesInput
#' @seealso
#' @export openmi.om.timeSeriesInput
#' @examples
openmi.om.timeSeriesInput <- setRefClass(
  "openmi.om.timeSeriesInput",
  fields = list(
    tsvalues = "ANY",
    intmethod = "integer",
    intflag = "integer"
  ),
  contains = "openmi.om.linkableComponent",
  # Define the logState method in the methods list
  methods = list(
    getInputs = function () {
      callSuper()
      # requires that the use has populated the tsvalues variable with an xts timeseries
      # get the current time slice
      tvals = tsvalues[timer$thistime]
      # @todo: handle non-exact time matches, either by preprocesing the tsvalues array
      #        to always have matching dates, or by using the xct methods to grab date range
      #        from thistime to (thistime - dt) and summarizing according to the method
      for (colname in names(tsvalues)) {
        data[colname] <<- tvals[,colname]
      }
    },
    update = function () {
      callSuper()
    },
    getValue = function(name = "value"){
      # returns the value.  Defaults to simple case where object only has one possible value
      if (name %in% names(data)) {
        return(data[name])
      }
      return(FALSE);
    }
  )
)

