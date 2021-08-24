#****************************
# Override logState() method and has write method on finish()
#****************************
#' The base class for logging component data.
#'
#' @return reference class of type openmi.om.linkableComponent
#' @seealso
#' @export openmi.om.logger
#' @examples NA
openmi.om.logger <- R6Class(
  'openmi.om.logger',
  inherit = openmi.om.linkableComponent,
  public = list(
    #' @field directory where to store log file
    directory = character(),
    #' @field path to store log file includes directory and filename
    path = character(),
    #' @field filename name to store log file
    filename = character(),
    #' @field outputs local state variables to output
    outputs = NA,
    #' @description log data at end of timestep
    #' @return NULL
    logState = function() {
      super$logState()
      if (!is.xts(self$outputs)) {
        # first time, we need to initialize our data columns which includes timestamp
        # @todo: be more parsimonius?
        self$outputs <- xts(data.frame(self$data), order.by = as.POSIXct(self$data$thistime))
      } else {
        self$outputs <- rbind(self$outputs, xts(data.frame(self$data), order.by = as.POSIXct(self$data$thistime)))
      }
    }
  )
)
