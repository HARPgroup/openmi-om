#' The base class for meta-model simulation control.
#'
#' @param
#' @return reference class of type openmi.om.runtimeController
#' @seealso
#' @export openmi.om.runtimeController
#' @examples
openmi.om.runtimeController <- setRefClass(
  "openmi.om.runtimeController",
  fields = list(
    code = "character"
  ),
  contains = "openmi.om.base",
  methods = list(
    checkRunVars = function() {
      if (!is.null(timer)) {
        if (is.null(timer$starttime)) {
          print("Timer$starttime required. Exiting.")
          return(FALSE)
        } else {
          if (is.null(timer$endtime)) {
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
      runok = checkRunVars()
      if (runok) {
        while (timer$status != 'finished') {
          print(paste("Model update() @", timer$thistime,sep=""))
          update()
        }
        print("Run completed.")
      } else {
        print("Could not complete run.")
      }
    },
    update = function() {
      callSuper()
      # Update the timer afterwards
      timer$update()
    },
    initialize = function() {
      callSuper()
      timer$initialize()
    }
  )
)
