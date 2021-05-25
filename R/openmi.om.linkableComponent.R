#' The base class for linkable meta-model components.
#'
#' @param
#' @return reference class of type openmi.om.linkableComponent
#' @seealso
#' @export openmi.om.linkableComponent
#' @examples
openmi.om.linkableComponent <- R6Class(
  "openmi.om.linkableComponent",
  inherit = "openmi.om.base",
  public = list(
    value = "numeric",
    code = "character"
  )
)
