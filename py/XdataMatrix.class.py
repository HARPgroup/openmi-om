from numba.experimental import jitclass
from numba import int8, float32, njit, types    # import the types
import numpy as np

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
        matrix_eval = eval(matrix_text)
        m_type = type(matrix_eval ).__name__
        if m_type == "list":
            return np.asarray(matrix_eval, dtype="float32")
        else:
            print(m_type)
            return False