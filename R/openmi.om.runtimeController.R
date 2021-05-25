#' The base class for meta-model simulation control.
#'
#' @param
#' @return reference class of type openmi.om.runtimeController
#' @seealso
#' @export openmi.om.runtimeController
#' @examples
#' @include openmi.om.linkableComponent.R
openmi.om.runtimeController <- R6Class(
  "openmi.om.runtimeController",
  inherit = openmi.om.base,
  public = list(
    code = character,
    initialize = function() {
      self$timer <- openmi.om.timer$new()
    },
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
    update = function() {
      super$update()
      # Update the timer afterwards
      self$timer$update()
    },
    init = function() {
      super$init()
      self$timer$init()
    }
  )
)
