#' Parse a list object to instantiate a model component/sub-component
#'
#' @param elem_list list with model descriptors
#' @return open.mi R6 class of matching type or generic R6 openmi.om.base
#' @seealso NA
#' @export openmi_om_load
#' @examples NA
openmi_om_load <- function (elem_list, timer = FALSE) {
  # all others that may be embedded inside it are ancillary
  # this will instantiate an object if it exists, pass the other 1st level
  # data into the object initialize() function which will handle any other attributes
  elem_obj <- openmi_om_load_single(elem_list)
  c <- 0
  if (!is.logical(elem_obj)) {
    #If timer is not set, set to the object passed in by user
    if(is.na(elem_obj$timer) && !is.logical(timer)){
      elem_obj$timer <- timer
    }

    for (j in names(elem_list)) {
      if (!is.na(match(j, c('object_class', 'name', 'value')))) {
        # these are special reserved words, so just skip
        # if value has any special things embedded in it
        # this should be handled by the object class plumbing set_prop
        next
      }
      j_list = elem_list[[j]]
      message(j)
      if (!is.na(match('object_class', names(j_list)))) {
        sub_obj <- openmi_om_load(j_list)
        # here we check to see if an object is returned.  If so, this is a legit
        # sub-comp.  Otherwise, if it is a settable property, it will have been handled
        # by the initial object creation, so we just discard
        if (as.character(typeof(sub_obj)) == 'environment') {
          message(paste("Adding component", sub_obj$name))
          elem_obj$add_component(sub_obj)
        }
      }
    }
  }
  return(elem_obj)
}

openmi_om_load_single <- function(elem_info) {
  elem_obj = FALSE
  if (!is.null(elem_info$object_class)) {
    message(paste("Found", elem_info$object_class))
    if (elem_info$object_class == 'Equation') {
      # we got this
      message(paste("instantiating", elem_info$name, " with object_class=", elem_info$object_class, " as openmi.om.equation class" ))
      elem_obj <- openmi.om.equation$new(elem_info, format = 'openmi')
    } else if (elem_info$object_class == 'hydroImpoundment') {
      # todo: create an object for this
      elem_obj <- openmi.om.base$new(elem_info, format = 'openmi')
    } else if (elem_info$object_class == 'DataMatrix') {
      # todo: create an object for this
      message(paste("instantiating", elem_info$name, " with object_class=", elem_info$object_class, " as openmi.om.matrix class" ))
      elem_obj <- openmi.om.matrix$new(elem_info, format = 'openmi')
    } else {
      message(paste("Adding", elem_info$object_class, " as base class" ))
      elem_obj <- openmi.om.base$new(elem_info, format = 'openmi')
    }
  }
  return(elem_obj)
}
