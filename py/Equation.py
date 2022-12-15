class Equation(modelObject):
    # the following are supplied by the parent class: name, log_path, attribute_path, state_path, inputs
    
    def __init__(self, name, state_ix, state_paths, dict_ix):
        super(Equation, self).__init__(name, state_ix, state_paths, dict_ix)
        self.equation = ""
        self.ps = False 
        self.optype = 1 # 0 - shell object, 1 - equation, 2 - datamatrix, 3 - input, 4 - broadcastChannel, 5 - ?
    
    def deconstruct_eqn(self):
        exprStack = []
        exprStack[:] = []
        print(exprStack)
        self.ps = deconstruct_equation(self.equation)
    
    def tokenize_ops(self):
        self.deconstruct_eqn()
        self.ops = tokenize_ops(self.ps)
    
    def tokenize_vars(self):
      # now stash the string vars as new state vars
      for j in range(2,len(self.ops)):
          if isinstance(self.ops[j], int):
              continue # already has been tokenized, so skip ahead
          elif is_float_digit(self.ops[j]):
              # must add this to the state array as a constant
              constant_path = self.state_path + '/_ops/_op' + str(j) 
              s_ix = set_state(self.state_ix, self.state_paths, constant_path, float(self.ops[j]) )
              self.ops[j] = s_ix
          else:
              # this is a variable, must find it's data path index
              var_path = self.find_var_path(self.ops[j])
              s_ix = get_state_ix(self.state_ix, self.state_paths, var_path)
              if s_ix == False:
                  print("Error: unknown variable ", self.ops[j])
                  return
              else:
                  self.ops[j] = s_ix
    
