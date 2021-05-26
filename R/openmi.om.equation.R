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
    numnull = 0,
    arithmetic_operators = NA,
    safe_envir = NA,
    settable = function() {
      return(c('name', 'equation', 'defaultval', 'minvalue', 'nonnegative'))
    },
    initialize = function(elem_list = list(), format = 'raw'){
      #message("Creating equation")
      super$initialize(elem_list, format)
      self$arithmetic_operators <- Map(
        get, self$get_operators()
      )
    },
    get_operators = function() {
      safe_f = c(
        "(", "+", "-", "/", "*", "^",
        "sqrt", "log", "log10", "log2", "exp", "log1p"
      )
      return(safe_f)
    },
    set_prop = function(propname, propvalue, format = 'raw') {
      super$set_prop(propname, propvalue, format)
      if (format == 'openmi') {
        propvalue = self$parse_openmi(propvalue)
      }
      # is it allowed to be set?
      if (propname == 'equation') {
        self$equation <- as.character(propvalue)
        #message(paste(" = ", propvalue))
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
      self$set_sub_prop(propname, propvalue, format)
    },
    init = function() {
      super$init()
      if (length(self$defaultvalue) == 0) {
        self$defaultvalue <- 0
      }
      self$value <- self$defaultvalue
      self$eq <- parse(text=self$equation)
    },
    update = function() {
      super$update()
      #message("Evaluating eq")
      # evaluating an equation should be:
      # 1. restricted to variables in the local $data array
      # step() in OM php
      preval = self$evaluate()
      self$value <- as.numeric(preval)
      if (self$debug) {
        message(paste("eq = ", self$equation, " value = ", self$value))
      }
      self$data$value <- self$value
    },
    evaluate = function(){
      value <- tryCatch(
        {
          safe_envir <- c(self$data, self$arithmetic_operators)
          #value <-eval(parse(text=self$equation), envir=safe_envir)
          value <-eval(self$eq, envir=safe_envir)
        },
        error=function(cond) {
          # if no. of errors not exceeded,
          self$numnull <- self$numnull + 1
          if (self$numnull <= 5) {
            message(paste("Could not evaluate"))
            message(cond)
          }
          # Choose a return value in case of error
          value <- self$defaultvalue
        }
      )
      if (typeof(value) == 'closure') {
        # Choose a return value in case of error
        self$numnull <- self$numnull + 1
        if (self$numnull <= 5) {
          message(paste("Eval returned a function - check equation names for reserved words with undefined local values"))
          message(self$data)
        }
        value <- self$defaultvalue
      }
      return(value)
    }
  )
)

