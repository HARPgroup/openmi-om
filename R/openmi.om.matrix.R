#' The base class for matrix/lokup table meta-model components.
#'
#' @param
#' @return reference class of type openmi.om.matrix
#' @seealso
#' @export openmi.om.matrix
#' @examples
openmi.om.matrix <- setRefClass(
  "openmi.om.matrix",
  fields = list(
    datamatrix = "matrix",
    intmethod = "integer",
    intflag = "integer",
    colindex = "ANY",
    rowindex = "ANY",
    coltype = "integer",
    rowtype = "integer"
  ),
  contains = "openmi.om.linkableComponent",
  # Define the logState method in the methods list
  methods = list(
    update = function () {
      callSuper()
      # @todo: currently only returns exact match row/col lookup
      #   - add types: 1-d (row only)
      #   - add interpolation methods: interpolate, stair-step (prev value)
      # stairstep
      # Note: when using switch, the matching arg must be a string
      #       it seems that R auto converts these to make correct matches
      valmatrix <- datamatrix
      # @todo: evaluate all the cells in valmatrix, for now it assumes
      #        that these are all numeric
      rowmatch <- findMatch(valmatrix, data$rowindex, rowtype)
      # @todo:
      #   this does not yet function.  It should first find:
      #   - a full row match (or interpolation of multiple rows if app)
      #   - then derive a value from the retrieved row
      mval <- findMatch(rowmatch, data$colindex, coltype)
      value <<- as.numeric(mval)
      code <<- as.character(mval)
      if (debug) {
        print(paste(
          "Found",
          data$rowindex,
          data$colindex,
          'vaue:',
          value,
          'code',
          code,
          sep = ' '
        ))
      }

    },

    findMatch = function (dm, ixval, ixtype = 0) {
      foundmatch = switch(
        ixtype,
        '0' = exactMatch(dm, ixval),
        '1' = interpolate(dm, ixval),
        '2' = stairStep(dm, ixval),
        '3' = closest(dm, ixval),
        # default
        exactMatch(dm, ixval)
      )
      return(foundmatch)
    },

    exactMatch = function(dm, ixval, rectype = 'row') {
      # match row & col exactly
      if (is.null(ncol(dm))) {
        rval = dm[ixval]
      } else {
        rval = dm[ixval,]
      }
      return(rval)
    },

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
      # apply desired ssearch function (stairStep, interp)
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

    initialize = function () {
      callSuper()
      # @todo: enable complex matching types: stair-step, interpolate
      # Case: Exact Match
      if (length(rowindex) == 0) {
        rowindex <<- 1
      }
      if (length(colindex) == 0) {
        colindex <<- 1
      }
      data['rowindex'] <<- rowindex
      data['colindex'] <<- colindex
      if (length(datamatrix) == 0) {
        datamatrix <<- matrix(nrow=1,ncol=1)
      }
      if (length(rowtype) == 0) {
        rowtype <<- as.integer(1)
      }
      if (length(coltype) == 0) {
        coltype <<- as.integer(1)
      }
    }
  )
)
