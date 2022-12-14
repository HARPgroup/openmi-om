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
        self.tops = [self.optype, self.ix] + tokenize_ops(self.ps)
    
    def tokenize_constants(self, state_ix):
        self.ps = deconstruct_equation(self.equation)
    
    def tokenize_vars(self, state_ix):
        self.tops = tokenize_constants(tops, state_ix)

teq = Equation()
teq.name = 'flowby'
teq.equation = "Qin * 0.8"
teq.tokenize_ops() 

    def prepare_model():
       self.set_paths();
       exprStack = []
       exprStack[:] = []
       self.deconstruct_eqn();
       self.tokenize_eqn();
       self.tokenize_constants();
       self.tokenize_vars();