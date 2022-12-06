from numba.experimental import jitclass
from numba import int8, float32, njit, types    # import the types
import numpy as np

# Generic Methods used later by classes and other code
@njit
def tbl_lookup(data_table, keyval, lutype, valcol):
    # this handle a 1.5d table, that is, it can interpolate rows, for a single column of a multicolumn table 
    # so it will perform the operation on the using the 0th row as the index for matching/interpolating
    # and will return the matched or interpolated value from the column indicated by valcol 
    if lutype == 2: #stair-step
        idx = (data_table[:, 0][0:][(data_table[:, 0][0:]- keyval) <= 0]).argmax()
        luval = data_table[:, valcol][0:][idx]
    elif lutype == 1: # interpolate
        luval = np.interp(keyval,data_table[:, 0][0:], data_table[:, valcol][0:])
        
    # show value at tis point
    return luval

@njit
def exec_tbl_eval(op, state_ix, dict_ix):
    ix = op[1]
    dix = op[2]
    mx_type = op[3] # not used yet, what type of table?  in past this was always 1-d or 2-d 
    key1_ix = op[4]
    #print("ix, dict_ix, mx_type, key1_ix", ix, dix, mx_type, key1_ix)
    lutype = op[5]
    valcol = op[8]
    data_table = dict_ix[dix]
    keyval = state_ix[key1_ix]
    #print("Key, ltype, val", keyval, lutype, valcol)
    result = tbl_lookup(data_table, keyval, lutype, valcol)
    return result


# Object definition 
spec = [
    ('lutype1', int8),               # a simple scalar field
    ('lutype2', int8),               # a simple scalar field
    ('matrix', float32[:,:]),       # an array field
    ('value', float32),             # a variable holding the evaluation of this object
    ('keyval', float32),            # a variable holding the key for lookup
    ('valcol', int8),                  # which column to use for the default evaluate() result
    ('datapath', types.string),                      # path in hdf5
    ('lukey1path', types.string),                      # path in hdf5
    ('lukey2path', types.string),                      # path in hdf5
]
@jitclass(spec)
class XdataMatrix(object):
    def __init__(self, lutype1, lutype2, matrix):
        self.lutype1 = lutype1
        self.lutype2 = lutype2
        self.matrix = matrix
    
    def evalSet(self, ts, step):
        luval = ts[self.lukey1path][step]
        self.value = self.lookup(luval, self.valcol)
        ts[self.datapath][step] = self.value
    
    def evaluate(self):
        self.value = self.lookup(self.keyval, self.valcol)
    
    def lookup(self, keyval, valcol):
        if self.lutype1 == 2: #stair-step
            idx = (self.matrix[:, 0][0:][(self.matrix[:, 0][0:]- keyval) <= 0]).argmax()
            luval = self.matrix[:, valcol][0:][idx]
        elif self.lutype1 == 1: # interpolate
            luval = np.interp(keyval,self.matrix[:, 0][0:], self.matrix[:, valcol][0:])
        
        return luval
    
    def parseMatrix(matrix_text):
        # NOTE: this cannot be used in @njit because the function eval is called.
        # probably need to move this function into separate methods.
        matrix_eval = eval(matrix_text)
        m_type = type(matrix_eval ).__name__
        if m_type == "list":
            return np.asarray(matrix_eval, dtype="float32")
        else:
            print(m_type)
            return False
    