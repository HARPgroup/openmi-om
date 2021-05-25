#' The base time-keeping class for simulation control.
#'
#' @param
#' @return reference class of type openmi.om.timer
#' @seealso
#' @import lubridate
#' @export openmi.om.timer
openmi.om.timer <- R6Class(
  "openmi.om.timer",
  public = list(
    starttime = NA,
    endtime = NA,
    thistime = NA,
    status = NA,
    mo = NA,
    da = NA,
    yr = NA,
    tz = NA,
    dt = NA, # time step increment in seconds,
    update = function() {
      if (length(self$thistime) == 0) {
        self$thistime <- self$starttime
        self$status <- 'running'
      }
      #thistime <- thistime + duration(dt, "seconds")
      self$thistime <- self$thistime + seconds(self$dt)
      self$mo <- as.integer(format(self$thistime,'%m'))
      self$da <- as.integer(format(self$thistime,'%d'))
      self$yr <- as.integer(format(self$thistime,'%Y'))
      if (self$thistime > self$endtime) {
        self$status <- 'finished'
      }
    },
    init = function() {
      if (length(self$dt) == 0) {
        self$dt <- 86400
      }
      self$mo <- as.integer(format(self$thistime,'%m'))
      self$da <- as.integer(format(self$thistime,'%d'))
      self$yr <- as.integer(format(self$thistime,'%Y'))
      self$status <- 'initialized'
    }
  )
)
