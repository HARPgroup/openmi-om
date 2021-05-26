#' The base class for timeseries meta-model components.
#'
#' @param
#' @return reference class of type openmi.om.timeSeriesInput
#' @seealso
#' @export openmi.om.timeSeriesInput
#' @examples
#' @include openmi.om.linkableComponent.R
openmi.om.timeSeriesInput <- setRefClass(
  "openmi.om.timeSeriesInput",
  fields = list(
    tsvalues = "ANY",
    intmethod = "integer",
    intflag = "integer"
  ),
  contains = "openmi.om.linkableComponent",
  # Define the logState method in the methods list
  methods = list(
    getInputs = function () {
      callSuper()
      # requires that the use has populated the tsvalues variable with an xts timeseries
      # get the current time slice
      # may use span i.e. tvals = tsvalues[paste(timer$lasttime, timer$thistime, sep=":")]
      # must then apply function if it results in multiple values
      tvals = tsvalues[timer$thistime]
      # @todo: handle non-exact time matches, either by preprocesing the tsvalues array
      #        to always have matching dates, or by using the xct methods to grab date range
      #        from thistime to (thistime - dt) and summarizing according to the method
      for (colname in names(tsvalues)) {
        data[colname] <<- tvals[,colname]
      }
    },
    update = function () {
      callSuper()
    },
    getValue = function(name = "value"){
      # returns the value.  Defaults to simple case where object only has one possible value
      if (name %in% names(data)) {
        return(data[name])
      }
      return(FALSE);
    }
  )
)
