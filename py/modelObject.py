class modelObject:
    name = "" # Ex: "Qin" 
    parent = False # will be a link to another object
    log_path = "" # Ex: "/RESULTS/RCHRES_001/SPECL" 
    attribute_path = "/OBJECTS/RCHRES_001" # 
    state_path = "" # Ex: "/STATE/RCHRES_001" # the pointer to this object state
    inputs = {} # associative array with key=local_variable_name, value=hdf5_path Ex: [ 'Qin' : '/STATE/RCHRES_001/IVOL' ]
    children = {} # associate array with attribute names and objects 
    state_ix = {} # Shared Dict with the numerical state of each object 
    state_paths = {} # Shared Dict with the hdf5 path of each object 
    dict_ix = {} # Shared Dict with the hdf5 path of each object 
    ix = False
    default_value = 0.0
    
    def __init__(self, name, state_ix, state_paths, dict_ix):
        self.name = name
        self.state_ix = state_ix
        self.state_paths = state_paths
        self.dict_ix = dict_ix
    
    def make_state_path(self):
        if not (self.parent == False):
            self.state_path = self.parent.state_path + "/" + self.name
        else:
            self.state_path = "/STATE/" + self.name
        return self.state_path
    
    def find_var_path(self, var_name):
        if var_name in self.inputs.keys():
            return self.inputs[var_name]
        if not (self.parent == False):
            return self.parent.find_var_path(var_name)
        return False
    
    def register_path(self):
        self.ix = set_state(self.state_ix, self.state_paths, self.state_path, self.default_value)
        return self.ix
    
    def add_input(self, var_name, var_path):
        # this will add to the inputs, but also insure that this 
        # requested path gets added to the state/exec stack via an input object if it does 
        # not already exist.
        self.inputs[var_name] = var_path
        return self.insure_path(var_path)
    
    def insure_path(self, var_path):
        # if this path can be found in the hdf5 make sure that it is registered in state
        # and that it has needed object class to render it at runtime (some are automatic)
        # RIGHT NOW THIS DOES NOTHING TO CHECK IF THE VAR EXISTS THIS MUST BE FIXED
        var_ix = set_state(self.state_ix, self.state_paths, var_path, 0.0)
        return var_ix 
    
    def get_state(self):
        return self.state_ix[self.ix]
