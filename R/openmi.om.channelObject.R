#' The base class for executable equation based meta-model components.
#'
#' @return reference class of type openmi.om.channelObject
#' @seealso
#' @export openmi.om.channelObject
#' @examples NA
#' @include openmi.om.linkableComponent.R
openmi.om.channelObject <- R6Class(
  "openmi.om.channelObject",
  inherit = openmi.om.linkableComponent,
  public = list(
    #' @field area the drainage area to this channel (square miles)
    area = 0.0,
    #' @field length the length of the channel segment (ft)
    length = 5000.0,
    #' @field base the channel bottom base in feet (used for trapezoidal or rectangular)
    base = 1.0,
    #' @field Z side slope
    Z = 1.0,
    #' @field slope channel slope
    slope = 1.0,
    #' @field n Manning's roughness coefficient
    n = 1.0,
    #' @field substrateclass substrate class (USGS hab model aram, A, B, C, D)
    substrateclass = 'C',
    #' @field channeltype channel shape (only trapezoidal channels, type=2 are currently supported)
    channeltype = 2,
    #' @field storageinitialized is the storage initialized on first exec?
    storageinitialized = 0,
    #' @field pdepth mean pool depth below channel bottom
    pdepth = 0.5,
    #' @field tol solution exactness tolerance to stop iterating.
    tol = 0.01,
    #' @description settable returns properties that can be set at initialize()
    #' @return array c() of object property names
    settable = function() {
      return(c('area', 'base', 'Z', 'length', 'tol',
               'pdepth', 'substrateclass', 'channeltype'))
    },
    #' @description create new instance of channel object
    #' @param elem_list list of attributes to set on object
    #' @param format data format of elem_list
    #' @return array c() of object property names
    initialize = function(elem_list = list(), format = 'raw'){
      #message("Creating channelObject")
      super$initialize(elem_list, format)
    },
    #' @description init sets up stream for model run
    #' @return NULL
    init = function() {
      # todo: put the storage initialization here
      #       check if this is a resumed run, we will restore from state
      super$init()
    },
    #' @description update executes the parsed equation, sets object value prop
    #' @return NULL
    update = function() {
      super$update() # this executes all the subcomps and processors
      #message("Evaluating eq")
      self$evaluate()
    },
    #' @description evaluate is called by update, but can also be called if calling routine wants the value returned
    #' @return value the result of the equation
    evaluate = function() {
      # solve the channel routing equation
      area = self$state['area'];
      Qafps = self$state['Qafps'];
      Rin = self$state['Rin'];
      discharge = self$state['discharge']; # get any point source discharges into this water body (MGD)
      Qlocal = 0.0;
      # get time step from timer object
      dt = self$timer$dt;

      if ( (area > 0) & (Qafps > 0)) {
        Qlocal = Qafps * area * 640.0 * 43560.0;
      }
      #error_log("Calculating Equation Qlocal += Rin - > $Qlocal += $Rin ;");
      if ( (Rin > 0) ) {
        Qlocal <- Qlocal + Rin;
      }
      #error_log("I2 = this$state['Qin'] + Qlocal + discharge * 1.547 $ $I2 = " . self$state['Qin'] . " + $Qlocal + $discharge * 1.547 ;");


      I2 <- self$state['Qin'] + Qlocal + discharge * 1.547
      if (self$debug) {
        self$log_debug(paste("Final Inflows I2 :", I2, " = ", self$state['Qin'], " + ", Qlocal, "+", discharge))
      }
      I1 = self$state['Iold'];
      O1 = self$state['Qout'];
      S1 = self$state['Storage'];
      initialStorage = self$state['Storage'];
      depth = self$state['depth'];
      demand = self$state['demand'];
      # avoid Storage < 0 by adjusting demand as much as possible
      demand_balance = demand - I2;
      rejected_demand_mgd = 0.0;
      rejected_demand_pct = 0.0;
      if ( (demand_balance > 0) & (demand > 0) ) {
        rejected_demand = demand_balance;
        rejected_demand_mgd = rejected_demand / 1.547;
        rejected_demand_pct = rejected_demand / demand;
        demand = demand - rejected_demand;
      }
      if (self$length > 0) {
        # if length is set to zero we automatically pass inflows

        if (self$storageinitialized == 0) {
          # first time, need to estimate initial storage,
          # assumes that we are in steady state, that is,
          # the initial and final Q, and S are equivalent
          I1 = I2;
          O1 = I2;
          if (self$debug) {
            self$log_debug("Estimating initial storage, calling: storageroutingInitS($I2, self$base, self$Z, self$channeltype, self$length, self$slope, $dt, self$n, self$units, 0)");
          }
          S1 = storageroutingInitS(I2, self$base, self$Z, self$channeltype, self$length, self$slope, dt, self$n, self$units, 0);
          if (self$debug) {
            self$log_debug("Initial storage estimated as $S1 <br>\n");
          }
          self$storageinitialized = 1;
        }


        if(self$debug) {
          dtime = self$timer$thistime$format('r');
          self$log_debug("Calculating flow at time $dtime <br>\n");
          self$log_debug("Iold = $I1, Qin = $I2, Last Qout = $O1, base = self$base, Z = self$Z, type = 2, Storage = $S1, length = self$length, slope = self$slope, $dt, n = self$n <br>\n");
          #die;
        }


        # now execute any operations
        #self$execProcessors();
        # re-calculate the channel flow parameters, if any other operations have altered the flow:
        list(Vout, Qout, depth, Storage, its) = storagerouting(I1, I2, O1, demand, self$base, self$Z, self$channeltype, S1, self$length, self$slope, dt, self$n, self$units, 0);
        if ( (I1 > 0) & (I2 > 0) & (demand < I1) & (demand < I2) & (Qout == 0) ) {
          # numerical error, adjust
          # @todo: revisit this.  If storage is available in the channel, flow may theoretically be 0.0
          #        but a withdrawal could be possible?  Mannings roughness etc?
            #        Also need to create handling of rejected demand.  That is, do not let the storage be < 0.0
          Qout = ((I1 + I2) / 2.0) - demand;
        }
      } else {
        # zero length channel, this is a pass-through - still decrement storage if we ask for it though
        Vout = 0.0;
        Storage = 0.0;
        depth = 0.0;
        if (demand > 0) {
          if (I2 > demand) {
            Qout = I2 - demand;
          } else {
            Qout = 0.0;
          }
        } else {
          Qout = I2;
        }
      }

      self$state['last_S'] = S1;
      self$state['Qin'] = I2;
      self$state['Qlocal'] = Qlocal;
      self$state['Vout'] = Vout;
      self$state['area'] = area;
      self$state['Qout'] = Qout;
      self$state['depth'] = depth;
      self$state['Storage'] = Storage;
      self$state['last_demand'] = demand;
      self$state['last_discharge'] = discharge;
      self$state['rejected_demand_mgd'] = rejected_demand_mgd;
      self$state['rejected_demand_pct'] = rejected_demand_pct;
      self$state['its'] = its;

      if(self$debug) {
        self$log_debug("Qout = $Qout <br>\n");
      }
      self$evaluate_heat()
      self$totalflow <- self$totalflow + as.numeric(Qout * dt);
      self$totalinflow <- self$totalinflow + as.numeric(I2 * dt);
      self$totalwithdrawn = self$totalwithdrawn + as.numeric(demand * dt);
    },
    #' @description evaluate is called by update, but can also be called if calling routine wants the value returned
    #' @return value the result of the equation
    evaluate_heat = function() {
      Uin = self$state['Uin']; # heat in
      U0 = self$state['U']; # heat in BTU/Kcal at previous timestep
      Temp = self$state['T']; # Temp at previous timestep
      # now calculate heat flux
      # O1 is outflow at last time step,
      U = (Storage * (U0 + Uin)) / ( Qout * dt + Storage)
      if (self$units == 1) {
        # SI
        Temp = U / Storage; # this is NOT right, don't know what units for storage would be in SI, since this is not really implemented
      } else if (self$units == 2) {
        # EE
        Temp = 32.0 + (U / (Storage * 7.4805)) * (1.0 / 8.34) # Storage - cubic feet, 7.4805 gal/ft^3
      }

      # let's also assume that the water isn't frozen, so we limit this to zero
      if (T < 0) {
        T = 0
      }
      Uout = U0 + Uin - U
      self$state['U'] <- as.numeric(U)
      self$state['Uout'] <- as.numeric(Uout)
      self$state['T'] <- as.numeric(Temp)
    }
  )
)

