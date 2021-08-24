library(stringr)
library(httr)
#' The base class for executable equation based meta-model components.
#'
#' @return reference class of type openmi.om.equation
#' @seealso
#' @export openmi.om.equation
#' @examples NA
#' @include openmi.om.linkableComponent.R
openmi.om.equation <- R6Class(
  "openmi.om.equation",
  inherit = openmi.om.linkableComponent,
  public = list(
    #' @field equation the text based un-parsed equation
    equation = NA,
    #' @field eq the ready to eval equation
    eq = NA,
    #' @field defaultvalue value to set if null
    defaultvalue = NA,
    #' @field minvalue minimum value to use if nonnegative = TRUE
    minvalue = NA,
    #' @field nonnegative should result be constrained to positive only?
    nonnegative = NA,
    #' @field numnull counter of occurences of null evaluation for debugging
    numnull = 0,
    #' @field arithmetic_operators operators to allow in equations
    arithmetic_operators = NA,
    #' @field safe_envir the set of values that are accessible to the equation during evaluation
    safe_envir = NA,
    #' @description settable returns properties that can be set
    #' @return array c() of object property names
    settable = function() {
      return(c('name', 'equation', 'defaultval', 'minvalue', 'nonnegative'))
    },
    #' @description create new instance of equation object
    #' @param elem_list list of attributes to set on object
    #' @param format data format of elem_list
    #' @return array c() of object property names
    initialize = function(elem_list = list(), format = 'raw'){
      #message("Creating equation")
      super$initialize(elem_list, format)
      self$arithmetic_operators <- Map(
        get, self$get_operators()
      )
    },
    #' @description get_operators returns list of valid functions
    #' @return array c() of function names
    get_operators = function() {
      safe_f = c(
        "(", "+", "-", "/", "*", "^",
        "sqrt", "log", "log10", "log2", "exp", "log1p"
      )
      return(safe_f)
    },
    #' @param propname which attribute
    #' @param propvalue what value
    #' @param format of propvalue
    #' @return NA
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
    #' @description init sets up data, parses equation and then passes on to parent class
    #' @return NULL
    init = function() {
      if (length(self$defaultvalue) == 0) {
        self$defaultvalue <- 0
      }
      self$value <- self$defaultvalue
      self$parse()
      super$init()
    },
    #' @description parse parses equation
    #' @return NULL
    parse = function () {
      self$eq <- parse(text=self$equation)
      # now that we've parsed we can get the variables and operators in use
    },
    #' @description set_vars finds all the input var names for this function
    #' @return NULL
    set_vars = function() {
      super$set_vars()
      plist <- getParseData(self$eq)
      for (i in 1:nrow(plist)) {
        pdi <- plist[i,]
        if (str_to_lower(pdi$token) == 'symbol') {
          if (is.na(match(pdi$text, self$vars))) {
            self$vars <- rbind(self$vars, pdi$text)
          }
        }
      }
    },
    #' @description update executes the parsed equation, sets object value prop
    #' @return NULL
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
    #' @description evaluate is called by update, but can also b called if calling routine wants the value returned
    #' @return value the result of the equation
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

