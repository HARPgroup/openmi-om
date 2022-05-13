#' The base class for executable equation based meta-model components.
#'
#' @return reference class of type openmi.om.channelObjectSimple
#' @seealso
#' @export openmi.om.channelObjectSimple
#' @examples NA
#' @include openmi.om.channelObject
openmi.om.channelObjectSimple <- R6Class(
  "openmi.om.channelObjectSimple",
  inherit = openmi.om.channelObject,
  public = list(
    #' @description calculate flow out during time step
    #' @return NULL
    update = function() {
      super$update()
      # perform a simple routing step
      # guessing mean storage (S) is the ciritical part of this timesaving
      # solution, since a good enough guess requires no iteration
      # init storage if needed at timestep 1
      if (self$storageinitialized == 0) {
        self$storageinitialized = 1
        S = 0
      } else {
        S = self$state['S'];
      }
      # find the solution
      solution_values <- self$QfS(S)
      if (update_state == TRUE) {
        self$set_state_list( solution_values )
      }
      self$set_state_list(solution_values)
    },
    #' @description s_f_Q calculate storage as a function of Q
    #' @param Q flow
    #' @return numeric
    SfQ_est = function(Q, dt) {
      # quick and dirty guess for Storage as a function of Q
      # assume zero at first tiem step, then
      S = 0.5 * Q * dt
      return(S)
    },
    #' @description s_f_Q calculate storage as a function of Q
    #' @param Q flow
    #' @return numeric
    SfQ_Euler = function(Q0, Qin1, dt) {
      # guess change in S based on change in S over change in Q from last timestep
      dSdQ = (S1 - S0) / (Qin1 - Q0) / dt
      S = dSdQ * dt
      return(S)
    },
    #' @description s_f_Q calculate storage as a function of Q
    #' @param Q flow
    #' @return numeric
    QfS = function(S, update_state = TRUE) {
      # calculate Q as a function of Storage
      A = S / self$length
      manco = 1.49 # should select based on object units
      d = (-1.0 * self$base + ( self$base^2.0 + 4.0 * A * self$Z) ^ 0.5 ) / (2.0 * self$Z)
      p = self$base + 2.0 * d * ( self$Z^2.0 + 1.0)^0.5
      R = A / p
      Q = A * (1.49/self$n) * R^(2.0/3.0) * self$slope^0.5
      V = Q / A
      return(list(A = A, d = d, p = p, R = R, Q = Q, V = V))
    },
    #' @description set_state_list sets state variables from a list
    #' @param arg_list thy set of key = value to store in the state array
    #' @return NULL
    set_state_list = function (arg_list = list()) {
      for (i in names(arg_list)) {
        message(paste("setting", i, "to", arg_list[[i]]))
        self$state[i] = arg_list[[i]]
      }
    }
  )
)
