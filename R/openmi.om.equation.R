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

