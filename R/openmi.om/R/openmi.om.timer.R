#' The base time-keeping class for simulation control.
#'
#' @param
#' @return reference class of type openmi.om.timer
#' @seealso
#' @import lubridate
#' @export openmi.om.timer
openmi.om.timer <- setRefClass(
  "openmi.om.timer",
  fields = list(
    starttime = "POSIXct",
    endtime = "POSIXct",
    thistime = "POSIXct",
    status = "character",
    mo = "integer",
    da = "integer",
    yr = "integer",
    tz = "integer",
    dt = "numeric" # time step increment in seconds
  ),
  methods = list(
    update = function() {
      if (length(thistime) == 0) {
        thistime <<- starttime
        status <<- 'running'
      }
      #thistime <<- thistime + duration(dt, "seconds")
      thistime <<- thistime + seconds(dt)
      mo <<- as.integer(format(thistime,'%m'))
      da <<- as.integer(format(thistime,'%d'))
      yr <<- as.integer(format(thistime,'%Y'))
      if (thistime > endtime) {
        status <<- 'finished'
      }
    },
    initialize = function() {
      if (length(dt) == 0) {
        dt <<- 86400
      }
      mo <<- as.integer(format(thistime,'%m'))
      da <<- as.integer(format(thistime,'%d'))
      yr <<- as.integer(format(thistime,'%Y'))
      status <<- 'initialized'
    }
  )
)
