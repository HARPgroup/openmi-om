library(stringr)
library(httr)
#' The base class for executable equation based meta-model components.
#'
#' @param
#' @return reference class of type openmi.om.equation
#' @seealso
#' @export openmi.om.equation
#' @examples
#' @include openmi.om.linkableComponent.R
openmi.om.equation <- R6Class(
  "openmi.om.equation",
  inherit = openmi.om.linkableComponent,
  public = list(
    equation = NA,
    eq = NA,
    defaultvalue = NA,
    minvalue = NA,
    nonnegative = NA,
    settable = function() {
      return(c('name', 'equation', 'defaultval', 'minvalue', 'nonnegative'))
    },
    initialize = function(elem_list = list(), format = 'raw'){
      message("Creating equation")
      super$initialize(elem_list)
    },
    set_prop = function(propname, propvalue, format = 'raw') {
      super$set_prop(propname, propvalue, format)
      if (format == 'openmi') {
        propvalue = self$parse_openmi(propvalue)
      }
      # is it allowed to be set?
      if (propname == 'equation') {
        message(paste("Equation parsing", self$name, "equation"))
        self$equation <- as.character(propvalue)
        message(paste(" = ", propvalue))
      }
      if (propname == 'defaultval') {
        self$defaultvalue <- propvalue
      }
      if (propname == 'defaultvalue') {
        self$defaultvalue <- propvalue
      }
      if (propname == 'minvalue') {
        self$minvalue <- propvalue
      }
      if (propname == 'nonnegative') {
        self$nonnegative <- propvalue
      }
      self$set_sub_prop(propname, propvalue)
    },
    init = function() {
      super$init()
      if (length(self$defaultvalue) == 0) {
        self$defaultvalue <- 0
      }
      self$value <- defaultvalue
      self$eq <- parse(text=equation)
    },
    update = function() {
      super$update()
      # evaluating an equation should be:
      # 1. restricted to variables in the local $data array
      # step() in OM php
      self$data$value <- value
      preval = eval(self$eq, self$data)
      self$value <- as.numeric(preval)
      if (debug) {
        message(paste("eq = ", self$equation, " value = ", self$value))
      }
    }
  )
)

