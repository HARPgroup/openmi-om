class Equation(modelObject):
    # the following are supplied by the parent class: name, log_path, attribute_path, state_path, inputs
    op_trios = [] # string array with sorted operand1, operand2, operator
    equation = ""; # string 
    tops = []
    optype = 1 # 1 - equation, 2 - datamatrix, 3 - input, 4 - container
    ix = False
    ps = False 
    
    def deconstruct_eqn(self):
        exprStack = []
        exprStack[:] = []
        print(exprStack)
        self.ps = deconstruct_equation(self.equation)
    
    def tokenize_ops(self):
        self.deconstruct_eqn()
        self.tops = tokenize_ops(self.ps)
    
    def tokenize_vars(self):
      # now stash the string vars as new state vars
      for j in range(2,len(self.tops)):
          if isinstance(self.tops[j], int):
              continue # already has been tokenized, so skip ahead
          elif is_float_digit(self.tops[j]):
              # must add this to the state array as a constant
              constant_path = self.state_path + '/_ops/_op' + str(j) 
              s_ix = set_state(self.state_ix, self.state_paths, constant_path, float(self.tops[j]) )
              self.tops[j] = s_ix
          else:
              # this is a variable, must find it's data path index
              var_path = self.find_var_path(self.tops[j])
              s_ix = get_state_ix(self.state_ix, self.state_paths, var_path)
              if s_ix == False:
                  print("Error: unknown variable ", self.tops[j])
                  return
              else:
                  self.tops[j] = s_ix
    
    def render_opcode(self):
        op_code = [self.optype, self.ix] + self.tops
        return op_code
