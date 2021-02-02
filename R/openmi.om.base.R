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
    },
    asJSON = function () {
      #TBD
    }
  )
)
