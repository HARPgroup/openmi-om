#' The base class for linkable meta-model components.
#'
#' @param
#' @return reference class of type openmi.om.linkableComponent
#' @seealso
#' @export openmi.om.linkableComponent
#' @examples
openmi.om.linkableComponent <- setRefClass(
  "openmi.om.linkableComponent",
  fields = list(
    value = "numeric",
    code = "character"
  ),
  contains = "openmi.om.base"
)
