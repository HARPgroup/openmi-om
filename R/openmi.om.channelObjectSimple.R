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
    #' @field S_negative_method strategy to use if S calculation is negative
    S_negative_method = 0,
    #' @description calculate flow out during time step
    #' @return NULL
    update = function(update_state = TRUE) {
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
    #' @param S_0 Storage at end of previous timestep
    #' @param Qout_0 mean outflow at previous timestep
    #' @param Qin_1 mean flow in during current timestep
    #' @param dt time-step
    #' @return numeric
    SfQ_lim = function(S_0, Qout_0, Qin_1, dt) {
      # get rate of change in Q as f(dS) in local flow context
      # max change in storage would be if no change in Qout with change Qin
      S_lim = S_0 + (Qin_1 - Qout_0) * dt
      message(paste("S_lim", S_lim))
      # calculate Qlim as outflow at f(Slim)
      Q_params = self$QfS(S_lim)
      Q_lim = as.numeric(Q_params$Q)
      message(paste("Q_lim", Q_lim))
      m = (S_lim - S_0) / (Q_lim - Qout_0)
      message(paste("m", m))
      # now, scale the change in s
      S_1 = m * (Q_lim - Qin_1) + S_0
      return(S_1)
    },
    #' @description SfQ_rect_euler calculate storage as a function of Q with Euler method
    #' @param S_0 Storage at end of previous timestep
    #' @param Qin_1 mean flow in during current timestep
    #' @param dt time-step
    #' @return numeric
    SfQ_rect_euler = function(S_0, Qin_1, dt) {
      S_1 = S_0 +
        (
          Qin_1 - (1.49/self$n) * (self$slope^0.5) * (1/self$length)
          *(
            ( ( S_0 * 43559.9 )^(5/2) )
            / ( self$base * self$length + 2 * (S_0*43559.9)/self$length )
           )^(2/3)
        ) * dt * 0.0000229569
      if (S_1 <0) {
        if (self$S_negative_method == 1) {
          S_1 = S_0
        } else {
          S_1 = 0
        }
      }
      return(S_1)
    },
    #' @description s_f_Q calculate storage as a function of Q
    #' @param Q flow
    #' @return numeric
    QfS_Q = function(Qin_1, S_0, S1, dt) {
      Q = Qin_1 - (S_1 - S_0)*43559.9/dt
    },
    #' @description s_f_Q calculate storage as a function of Q
    #' @param Q flow
    #' @return numeric
    QfS = function(S) {
      # calculate Q as a function of Storage
      A = S / self$length
      manco = 1.49 # should select based on object units
      if (self$channeltype == 1) {
        # rectangular
        d = A / self$base
        p = 2 * d + self$base # wetted perimeter calc for rectangular
      } else {
        # default to channel
        # if (self$channeltype == 2
        d = (-1.0 * self$base + ( self$base^2.0 + 4.0 * A * self$Z) ^ 0.5 ) / (2.0 * self$Z)
        p = self$base + 2.0 * d * ( self$Z^2.0 + 1.0)^0.5
      }
      R = A / p # hydraulic radius calc
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
