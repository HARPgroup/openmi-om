#' The base class for timeseries meta-model components.
#'
#' @return reference class of type openmi.om.timeSeriesInput
#' @export openmi.om.timeSeriesInput
#' @examples NA
#' @include openmi.om.linkableComponent.R
openmi.om.timeSeriesInput <- R6Class(
  "openmi.om.timeSeriesInput",
  inherit = openmi.om.linkableComponent,
  public = list(
    #' @field tsvalues holds the timeseries data
    tsvalues = NA,
    #' @field intmethod describes how to handle when current time does not match table exactly
    intmethod = 0,
    #' @field intflag 0 - always interpolate, 1 - never interpolate, 2 - interpolate up to a distance of ilimit seconds
    intflag = 0,
    #' @field ilimit interpolation/extrapolation limit
    ilimit = 432000.0,
    #' @field tscols fields in source timeseries dataset
    tscols = NA,
    #' @description init sets up for viewing or run
    #' @return NULL
    init = function() {
      super$init
      # TBD - this is not yet functional
      # - need to use new methods to harmonize on timestamp in this step so
      #   execution can proceed rapidly instead of interpolating every step
      # load data, so we can at least get our column header
    },
    #' @description set_names sets up tscols from timeseries source
    #' @return NULL
    set_names = function () {
      self$tscols = names(self$tsvalues)
    },
    #' @description add timeseries values to the data array
    #' @return NULL
    getInputs = function () {
      super$getInputs()
      # requires that the use has populated the tsvalues variable with an xts timeseries
      # get the current time slice
      # may use span i.e. tvals = tsvalues[paste(timer$lasttime, timer$thistime, sep=":")]
      # must then apply function if it results in multiple values
      tvals = self$tsvalues[self$timer$thistime]
      # this should move to init() ??
      if (is.na(self$tscols)) {
        self$set_names()
      }
      # @todo: handle non-exact time matches, either by preprocesing the tsvalues array
      #        to always have matching dates, or by using the xct methods to grab date range
      #        from thistime to (thistime - dt) and summarizing according to the method
      for (colname in self$tscols) {
        self$data[colname] <- tvals[,colname]
      }
    }
  )
)
