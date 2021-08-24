#' The base class for meta-model simulation control.
#'
#' @description Class providing a runnable model controller
#' @details Will iterate through time steps from model timer start to end time, executing all child components
#' @importFrom R6 R6Class
#' @return R6 class of type openmi.om.runtimeController
#' @seealso NA
#' @export openmi.om.runtimeController
#' @examples NA
openmi.om.runtimeController <- R6Class(
  "openmi.om.runtimeController",
  inherit = openmi.om.linkableComponent,
  public = list(
    #' @description create controller
    #' @return R6 class
    initialize = function() {
      self$timer <- openmi.om.timer$new()
    },
    #' @return boolean if model variables are sufficient to run
    checkRunVars = function() {
      if (!is.null(self$timer)) {
        if (is.null(self$timer$starttime)) {
          print("Timer$starttime required. Exiting.")
          return(FALSE)
        } else {
          if (is.null(self$timer$endtime)) {
            print("Timer$endtime required. Exiting.")
            return(FALSE)
          }
        }
      } else {
        print("Timer object is not set. Exiting.")
        return(FALSE)
      }
      return(TRUE)
    },
    #' @return NA
    run = function() {
      runok = self$checkRunVars()
      if (runok) {
        while (self$timer$status != 'finished') {
          print(paste("Model update() @", self$timer$thistime,sep=""))
          self$update()
        }
        print("Run completed.")
      } else {
        print("Could not complete run.")
      }
    },
    #' @return NA
    update = function() {
      super$update()
      # Update the timer afterwards
      self$timer$update()
    },
    #' @return NA
    init = function() {
      super$init()
      self$timer$init()
    }
  )
)
