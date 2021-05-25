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
    equation = character,
    eq = expression,
    defaultvalue = numeric,
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

