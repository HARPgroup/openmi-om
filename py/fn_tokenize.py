import numpy as np
import time
from numba.typed import Dict
from numpy import zeros
from numba import int8, float32, njit, types    # import the types


def deconstruct_equation(eqn):
    # we parse the equation during readuci/pre-processing and break it into njit'able pieces
    # this forms the basis of our object parser code to run at import_uci step 
    results = BNF().parseString(eqn, parseAll=True)
    ps = []
    ep = exprStack
    pre_evaluate_stack(ep[:], ps)
    return ps


def tokenize_ops(ps):
    tops = [len(ps)] # first token is number of ops
    for i in range(len(ps)):
        if ps[i][0] == '-': op = 1
        if ps[i][0] == '+': op = 2
        if ps[i][0] == '*': op = 3
        if ps[i][0] == '/': op = 4
        if ps[i][0] == '^': op = 5
        if ps[i][1] == None: o1 = -1 
        else: o1 = ps[i][1]
        if ps[i][2] == None: o2 = -1 
        else: o2 = ps[i][2]
        tops.append(op)
        tops.append(o1)
        tops.append(o2)
    return tops

def tokenize_eqn(ps):
    tops = [-1, -1, len(ps)] # set up placeholders for the first 2 op class type and state_ix
    for i in range(len(ps)):
        if ps[i][0] == '-': op = 1
        if ps[i][0] == '+': op = 2
        if ps[i][0] == '*': op = 3
        if ps[i][0] == '/': op = 4
        if ps[i][0] == '^': op = 5
        if ps[i][1] == None: o1 = -1 
        else: o1 = ps[i][1]
        if ps[i][2] == None: o2 = -1 
        else: o2 = ps[i][2]
        tops.append(op)
        tops.append(o1)
        tops.append(o2)
    return tops

def tokenize_constants(tops, state_ix):
  # now stash the string vars as new state vars
  for j in range(len(tops)):
      if isinstance(tops[j], str):
          # must add this to the state array as a constant
          s_ix = append_state(state_ix, float(tops[j]))
          tops[j] = s_ix


def find_state_path(state_paths, parent_path, varname):
    # this is a bandaid, we should have an object routine that searches the parent for variables or inputs
    var_path = parent_path + "/states/" + str(varname)
    return var_path


def get_state_ix(state_ix, state_paths, var_path):
    if not (var_path in state_paths.keys()):
        # we need to add this to the state 
        return False # should throw an error 
    var_ix = state_paths[var_path]
    return var_ix


def set_state(state_ix, state_paths, var_path, default_value = 0.0):
    if not (var_path in state_paths.keys()):
        # we need to add this to the state 
        state_paths[var_path] = append_state(state_ix, default_value)
    var_ix = state_paths[var_path]
    return var_ix

def append_state(state_ix, var_value):
    if (len(state_ix) == 0):
      val_ix = 1
    else:
        val_ix = max(state_ix.keys()) + 1 # next ix value
    state_ix[val_ix] = var_value
    return val_ix

def init_op_tokens(op_tokens, tops, eq_ix):
    # now stash the string vars as new state vars
    for j in range(len(tops)):
        if isinstance(tops[j], str):
            # must add this to the state array as a constant
            s_ix = append_state(state_ix, float(tops[j]))
            tops[j] = s_ix

    op_tokens[eq_ix] = np.asarray(tops, dtype="i8")

def is_float_digit(n: str) -> bool:
     try:
         float(n)
         return True
     except ValueError:
         return False

@njit 
def exec_op_tokens(op_tokens, state_ix, dict_ix, steps):
    checksum = 0.0
    for step in range(steps):
        for i in op_tokens.keys():
            s_ix = op_tokens[i][1] # index of state for this component
            if op_tokens[i][0] == 1:
                state_ix[s_ix] = exec_eqn_nall_m(op_tokens[i], state_ix)
            elif op_tokens[i][0] == 2:
                state_ix[s_ix] = exec_tbl_eval(op_tokens[i], state_ix, dict_ix)
            checksum += state_ix[i]
    return checksum


@njit
def exec_eqn_nall_m(op_token, state_ix):
    op_class = op_token[0] # we actually will use this in the calling function, which will decide what 
                      # next level function to use 
    result = 0
    num_ops = op_token[2]
    s = np.array([0.0])
    s_ix = -1 # pointer to the top of the stack
    s_len = 1
    #print(num_ops, " operations")
    # todo: the default is to iterate through all pairs, however, we could identify known forms
    #       such as (x * y) / z 
    #       and whenever that opcode sequence occurs, we could do the eval in a single step, cutting ops in half
    #       more complex forms with 4 or 5 ops could have even more time savings.    
    for i in range(num_ops): 
        op = op_token[3 + 3*i]
        t1 = op_token[3 + 3*i + 1]
        t2 = op_token[3 + 3*i + 2]
        # if val1 or val2 are < 0 this means they are to come from the stack
        # if token is negative, means we need to use a stack value
        #print("s", s)
        if t1 < 0: 
            val1 = s[s_ix]
            s_ix -= 1
        else:
            val1 = state_ix[t1]
        if t2 < 0: 
            val2 = s[s_ix]
            s_ix -= 1
        else:
            val2 = state_ix[t2]
        #print(s_ix, op, val1, val2)
        if op == 1:
            #print(val1, " - ", val2)
            result = val1 - val2
        elif op == 2:
            #print(val1, " + ", val2)
            result = val1 + val2
        elif op == 3:
            #print(val1, " * ", val2)
            result = val1 * val2 
        elif op == 4:
            #print(val1, " / ", val2)
            result = val1 / val2 
        elif op == 5:
            #print(val1, " ^ ", val2)
            result = pow(val1, val2) 
        s_ix += 1
        if s_ix >= s_len: 
            s = np.append(s, 0)
            s_len += 1
        s[s_ix] = result
    result = s[s_ix]
    return result 

def init_sim_dicts():
    op_tokens = Dict.empty(key_type=types.int64, value_type=types.i8[:])
    state_paths = Dict.empty(key_type=types.unicode_type, value_type=types.int64)
    state_ix = Dict.empty(key_type=types.int64, value_type=types.float64)
    dict_ix = Dict.empty(key_type=types.int64, value_type=types.float32[:,:])
    return op_tokens, state_paths, state_ix, dict_ix

def op_path_name(operation, id):
    tid = str(id).zfill(3)
    path_name = f'{operation}_{operation[0]}{tid}'
    return path_name

def specl_state_path(operation, id, activity):
    op_name = op_path_name(operation, id) 
    op_path = f'/STATE/{op_name}/{activity}'
    return op_path

# 
