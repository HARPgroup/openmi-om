#' The base class for matrix/lokup table meta-model components.
#'
#' @return R6 class of type openmi.om.matrix
#' @seealso
#' @export openmi.om.matrix
#' @examples NA
#' @include openmi.om.linkableComponent.R
openmi.om.matrix <- R6Class(
  "openmi.om.matrix",
  inherit = openmi.om.linkableComponent,
  public = list(
    #' @field datamatrix holds the actual table
    datamatrix = NA,
    #' @field colindex holds the column lookup variable name (ustabe keycol1)
    colindex = NA,
    #' @field rowindex holds the column lookup variable name (ustabe keycol2)
    rowindex = NA,
    #' @field coltype holds the column lookup type (ustabe lutype1)
    coltype = NA,
    #' @field rowtype holds the row lookup type (ustabe lutype2)
    rowtype = NA,
    #' @param propname which attribute
    #' @param propvalue what value
    #' @param format of propvalue
    #' @return NA
    set_prop = function(propname, propvalue, format = 'raw') {
      super$set_prop(propname, propvalue, format)
      if (format == 'openmi') {
        propvalue = self$parse_openmi(propvalue)
      }
      if (propname == 'matrix') {
        self$datamatrix <- propvalue
      }
      self$set_sub_prop(propname, propvalue, format)
    },
    #' @param propvalue from some custom classformat reading implementation
    #' @return a settable data value
    parse_class_specific = function(propvalue) {
      # special handlers for each class go here
      message("Called parse_class_specific on matrix()")
      print(propvalue)

      propvalue <- as.character(propvalue[['value']])
      return(propvalue)
    },
    #' @description update does the lookup
    #' @return NULL
    update = function () {
      super$update()
      # @todo: currently only returns exact match row/col lookup
      #   - add types: 1-d (row only)
      #   - add interpolation methods: interpolate, stair-step (prev value)
      # stairstep
      # Note: when using switch, the matching arg must be a string
      #       it seems that R auto converts these to make correct matches
      valmatrix <- self$datamatrix
      # @todo: evaluate all the cells in valmatrix, for now it assumes
      #        that these are all numeric
      rowmatch <- self$findMatch(valmatrix, self$data$rowindex, self$rowtype)
      # @todo:
      #   this does not yet function.  It should first find:
      #   - a full row match (or interpolation of multiple rows if app)
      #   - then derive a value from the retrieved row
      mval <- self$findMatch(rowmatch, self$data$colindex, self$coltype)
      value <- as.numeric(mval)
      code <- as.character(mval)
      if (debug) {
        print(paste(
          "Found",
          self$data$rowindex,
          self$data$colindex,
          'vaue:',
          value,
          'code',
          code,
          sep = ' '
        ))
      }

    },
    #' @description findMatch looks into a single dimension table
    #' @param dm array to search
    #' @param ixval key to search for
    #' @param ixtype what kind of lookup to perform?
    #' @return matching value (with interpolation if ixtype allows it)
    findMatch = function (dm, ixval, ixtype = 0) {
      foundmatch = switch(
        ixtype,
        '0' = self$exactMatch(dm, ixval),
        '1' = self$interpolate(dm, ixval),
        '2' = self$stairStep(dm, ixval),
        '3' = self$closest(dm, ixval),
        # default
        self$exactMatch(dm, ixval)
      )
      return(foundmatch)
    },
    #' @description exactMatch looks for keys
    #' @param dm array to search
    #' @param ixval key to search for
    #' @param rectype what kind of array is dm?
    #' @return matching value
    exactMatch = function(dm, ixval, rectype = 'row') {
      # match row & col exactly
      if (is.null(ncol(dm))) {
        rval = dm[ixval]
      } else {
        rval = dm[ixval,]
      }
      return(rval)
    },
    #' @description interpolate searches by key and calculates if no exact match
    #' @param dm array to search
    #' @param ixval key to search for
    #' @return interpolated value
    interpolate = function(dm, ixval) {
      # @todo: make this work
      #        for now, return exact match
      if (is.null(ncol(dm))) {
        rval = dm[ixval]
      } else {
        rval = dm[ixval,]
      }
      return(rval)
    },
    #' @description stairStep searches by key and select closest previous
    #' @param dm array to search
    #' @param ixval key to search for
    #' @return closest value
    stairStep = function(dm, ixval) {
      # match nearest val that is less than or equal to ixval
      if (is.null(ncol(dm))) {
        # given only a 1-column entity
        lm = dm
      } else {
        lm = dm[,1]
      }
      ixs = (ixval - lm) >= 0
      rix = max(which(ixs))
      if (is.null(ncol(dm))) {
        rval = dm[rix]
      } else {
        rval = dm[rix,]
      }
      return(rval)
    },
    #' @description window does what???
    #' @param dm array to search
    #' @param ixval key to search for
    #' @param ixoff index offset
    #' @return calculated value
    window = function(dm, ixval, ixoff) {
      # get values prior to and after ixval, use ixoff to help guess
      if (is.null(ncol(dm))) {
        # given only a 1-column entity
        lm = dm
      } else {
        lm = dm[,1]
      }
      # get closest match to ixval
      # search for previous and next to ixval
      # create a matrix with the 3 entries before ixval, ixval, and after ixval
      # apply desired search function (stairStep, interp)
      # could use the "closest()" method below???
      # - Or is there a more convenient R func?
      six = which.min(abs(lm - ixval + ixoff)); # guess start of interval
      eix = which.min(abs(lm - ixval + ixoff)); # guess end of interval
      if (is.null(ncol(dm))) {
        rval = dm[rix]
      } else {
        rval = dm[rix,]
      }
      return(rval)
    },
    #' @description closest select closest value
    #' @param dm array to search
    #' @param ixval key to search for
    #' @return closest value
    closest = function(dm, ixval) {
      # match row & col exactly
      if (is.null(ncol(dm))) {
        # given only a 1-column entity
        lm = dm
      } else {
        lm = dm[,1]
      }
      rix = which.min(abs(lm - ixval))
      if (is.null(ncol(dm))) {
        rval = dm[rix]
      } else {
        rval = dm[rix,]
      }
      return(rval)
    },
    #' @description init sets up for viewing or run
    #' @return NULL
    init = function () {
      super$init()
      # @todo: enable complex matching types: stair-step, interpolate
      # Case: Exact Match
      if (length(self$rowindex) == 0) {
        self$rowindex <- 1
      }
      if (length(self$colindex) == 0) {
        self$colindex <- 1
      }
      self$data['rowindex'] <- rowindex
      self$data['colindex'] <- colindex
      if (length(self$datamatrix) == 0) {
        self$datamatrix <-matrix(nrow=1,ncol=1)
      }
      if (length(self$rowtype) == 0) {
        self$rowtype <-as.integer(1)
      }
      if (length(self$coltype) == 0) {
        self$coltype <-as.integer(1)
      }
    }
  )
)
