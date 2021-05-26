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
    value = NA,
    data = NA,
    inputs = NA,
    components = NA,
    host = NA,
    type = NA,
    compid = NA,
    timer = openmi.om.timer,
    id = NA,
    initialize = function(elem_list = list(), format = 'raw'){
      for (i in names(elem_list)) {
        self$set_prop(i, elem_list[[i]], format)
      }
    },
    settable = function() {
      return(c('name', 'host'))
    },
    set_prop = function(propname, propvalue, format = 'raw') {
      if (format == 'openmi') {
        propvalue = self$parse_openmi(propvalue)
      }
      # is it allowed to be set?
      if (propname == 'name') {
        self$name <- propvalue
      }
      if (propname == 'host') {
        self$host <- propvalue
      }
      self$set_sub_prop(propname, propvalue)
    },
    parse_openmi = function(propvalue) {
      # check for special handlers needed
      # all openMI formatted will have a object_class and value field
      if (match('object_class', names(propvalue))) {
        object_class = as.character(propvalue[['object_class']])
      } else {
        # assume it's textField
        object_class = 'textField'
      }
      if (is.na(match('value', names(propvalue)))) {
        propvalue = NULL
      } else {
        if (object_class == 'textField') {
          propvalue <- as.character(propvalue[['value']])
        } else {
          # TBD: handle other types like data matrix in child classes
          propvalue <- as.character(propvalue[['value']])
        }
      }
      return(propvalue)
    },
    set_sub_prop = function(propname, propvalue) {
      if (!is.na(match(propname, names(self$components)))) {
        # pass to the component
        obj <- self$components[propname]
        obj$set_prop(propname, propvalue)
      }
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
      # this is deprecated in favor of the naming convention _
      return(self$add_component(thiscomp))
    },
    # components are small objects that reside inside this object
    # these *were* called processors in the old version of the model
    # other models are handled exclusively by the runtime controller/container
    # and they *may be* known as model_entities -- or they may *also*
    # be known as components: is there any reason
    # to have a separate concept of components and sub_components? run hierarchy?
    add_component = function (thiscomp = openmi.om.base) {
      compid = self$get_component_id(thiscomp)
      message(paste("Created compid =", compid))
      thiscomp$compid <- compid
      thiscomp$timer = self$timer
      self$components[compid] <- list('object' = thiscomp)
    },
    get_component_id = function(thiscomp) {

      # we can add this with numeric indices if we like
      # however, we must have a way of linking objects, which
      # requires a persistent name, i.e. a sort of DOI
      # format: host:type:id, examples:
      #   localhost:feature:647 (well 647),
      #   localhost:component:1991 (the withdrawal amt)
      # Input/Link format:
      #   localname:host:type:id:[remote name]
      #   - if property name is null then just use getValue() without parameter
      #print(thiscomp$compid)

      # we may need to use this for model controllers, but for now we just return the name
      return(as.character(thiscomp$name))

      # tbd: do we need this for *regular* models, not containers?
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
      thiscomp$compid = paste(thiscomp$name, thiscomp$host,thiscomp$type,thiscomp$id, sep=":")
      return(thiscomp)
    },
    orderOperations = function () {
      # sets basic hierarchy of execution by re-ordering the components list
    },
    asJSON = function () {
      #TBD
    }
  )
)

