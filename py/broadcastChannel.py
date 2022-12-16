class broadcastChannel(modelObject):
    # the following are supplied by the parent class: name, log_path, attribute_path, state_path, inputs
    # broadcastChannel receives data.  it has 2 addresses, 
    #   - the receiver /STATE/HostObject/BroadcastName/inputs = the sum total of the inputs 
    #   - the actual state value STATE/HostObject/VarName = the final total of the inputs at end of step 
    # during the pre-step phase both are set to 0.0, during evaluate, the parent object can determine if the write will be performed?
    
    def __init__(self, name, container = False):
        super(broadcastChannel, self).__init__(name, container)
        self.optype = 4 # broadcastChannel type