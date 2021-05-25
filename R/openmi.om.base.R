#' The base object class for meta-model components.
#'
#' @param
#' @return reference class of type openmi.om.base.
#' @seealso
#' @export openmi.om.base
#' @examples
#' @include openmi.om.timer.R
openmi.om.base <- R6Class(
  'openmi.om.base',
  public = list(
    name = NA,
    debug = NA,
    value = numeric,
    data = NA,
    inputs = NA,
    components = NA,
    host = NA,
    type = NA,
    compid = NA,
    timer = openmi.om.timer,
    id = NA,
    initialize = function(elem_list = list()){
    },
    init = function(){
      if (length(self$debug) == 0) {
        self$debug <- FALSE
      }
      # init() in OM php
      if (!is.na(self$components)) {
        if (length(self$components) > 0) {
          for (i in 1:length(self$components)) {
            self$components[[i]]$init()
          }
        }
      }
    },
    # added to base specification
    getInputs = function () {
      # get data from related objects or internal timeseries feeds
      # @todo: determine if we should clear data array at time begin
      # store in internal "data" list
      self$data$mo <- self$timer$mo
      self$data$da <- self$timer$da
      self$data$yr <- self$timer$yr
      self$data$thistime <- self$timer$thistime
      if (length(names(self$inputs)) > 0) {
        nms = names(self$inputs)
        for (i in 1:length(nms)) {
          i_name = nms[i]
          for (j in 1:length(self$inputs[i_name])) {
            input = self$inputs[[i_name]][[j]]
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
                self$data[i_name] <- 0
              }
              self$data[i_name] <- self$data[[i_name]] + as.numeric(i_value)
              #data[i_name] <- i_value
              if (debug) {
                print(paste("obtained and converted input", i_name, i_value,sep='='))
              }
            }
          }
        }
      }
    },
    prepare = function(){
      # preStep() in OM php
      self$getInputs()
    },
    update = function(){
      # step() in OM php
      self$prepare()
      if (!is.na(self$components)) {
        for (i in 1:length(self$components)) {
          self$components[[i]]$update()
        }
      }
      self$finish()
      self$logState()
    },
    finish = function(){
      # postStep() in OM php
      if (!is.na(self$components)) {
        if (length(self$components) > 0) {
          for (i in 1:length(self$components)) {
            self$components[[i]]$finish()
          }
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
      return(self$value)
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
      if (is.null(self$inputs[[local_name]])) {
        self$inputs[[local_name]] <- list()
        print(paste("adding", local_name, self$inputs[local_name]))
      }
      iid = length(self$inputs[[local_name]]) + 1
      self$inputs[[local_name]][iid] <- list(
        input = list(
          local_name = local_name,
          object = object,
          remote_name = remote_name,
          input_type = input_type
        )
      )
    },
    addComponent = function (thiscomp = openmi.om.base) {
      if (length(thiscomp$host) == 0) {
        thiscomp$host = 'localhost'
      }
      if (length(thiscomp$type) == 0) {
        thiscomp$type = 'unknown'
      }
      if (length(thiscomp$id) == 0) {
        if (is.na(self$components)) {
          cid = 1
        } else {
          cid = length(self$components) + 1
        }
        thiscomp$id = paste('local', cid, sep='');
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
      thiscomp$timer = self$timer
      self$components[thiscomp$compid] <- list('object' = thiscomp)
    },
    orderOperations = function () {
      # sets basic hierarchy of execution by re-ordering the components list
    },
    asJSON = function () {
      #TBD
    }
  )
)

