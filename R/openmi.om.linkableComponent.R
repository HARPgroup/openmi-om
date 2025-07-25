#' The base class for linkable meta-model components.
#'
#' @return R6 class of type openmi.om.linkableComponent
#' @importFrom R6 R6Class
#' @seealso
#' @export openmi.om.linkableComponent
#' @examples NA
openmi.om.linkableComponent <- R6Class(
  "openmi.om.linkableComponent",
  inherit = openmi.om.base,
)
