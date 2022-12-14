class modelObject:
    name = "" # Ex: "Qin" 
    parent = False # will be a link to another object
    log_path = "" # Ex: "/RESULTS/RCHRES_001/SPECL" 
    attribute_path = "/OBJECTS/RCHRES_001" # 
    state_path = "" # Ex: "/STATE/RCHRES_001" # the pointer to this object state
    inputs = {} # associative array with key=local_variable_name, value=hdf5_path_of_source_variable_state
                      # like: [ 'Qin' : '/STATE/RCHRES_001/IVOL' ]
    
    def state_path(self):
        if not (self.parent == False):
            return self.parent.state_path() + "/" + self.name
        return "/STATE/" + self.name
    
    def find_var_path(self, var_name):
        if var_name in self.inputs.keys():
            return self.inputs[var_name]
        if not (self.parent == False):
            return self.parent.find_var_path(var_name)
        return False
    
    def add_input(self, var_name, var_path):
        # this will add to the inputs, but also insure that this 
        # requested path gets added to the state/exec stack via an input object if it does 
        # not already exist.
        self.inputs[var_name] = var_path

