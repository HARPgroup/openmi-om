class dataMatrix(modelObject):
    lu_type1 = ""
    matrix = [] # gets passed in at creation.  Refers to path "/OBJECTS/DataMatrix/RCHRES_0001/stage_storage_discharge/matrix"
    def ncode_step(self):
        # return string with code that is executable in @njit function with ts and object state variables
        code_lines = []
        if self.lu_type1 == "":
            # this is only sample code of what a sample lookup might look like
            # note: three consecutive quote marks (""") tell python that this is a multi-line string
            code_lines.append("""OBJECTS_DATAMTRIX_0001 = array([[0.000000e+00, 1.700000e+02, 0.000000e+00],
                [1.952000e+05, 2.400000e+02, 8.890600e+03],
                [2.042528e+05, 2.410000e+02, 9.301500e+03],
                [2.137360e+05, 2.420000e+02, 9.712500e+03]])""")
            code_lines.append('ts["/RESULTS/RCHRES_001/SPECL/elev"][step] = np.interp(ts["/RESULTS/RCHRES_001/SPECL/Volume"][step],OBJECTS_DATAMATRIX_0001[:, 0][0:], OBJECTS_DATAMATRIX_0001[:, 1][0:])')
    
    def tokenize(self):
        # - insure we have a entity_ix pointing to state_ix
        # - check matrix for string vars and get entity_ix for string variables 
        # - add numerical constants to the state_ix and get the resulting entity_ix
        # - format array of all rows and columns state_ix references 
        # - store array in dict_ix keyed with entity_ix
        # - get entity_ix for lookup key(s)
        # - create tokenized array with entity_ix, lookup types, 