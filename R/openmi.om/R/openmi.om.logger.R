#****************************
# Override logState() method and has write method on finish()
#****************************
#' The base class for logging component data.
#'
#' @param
#' @return reference class of type openmi.om.linkableComponent
#' @seealso
#' @export openmi.om.logger
#' @examples
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
