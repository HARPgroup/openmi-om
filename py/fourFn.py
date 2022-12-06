# fourFn.py
#
# Demonstration of the pyparsing module, implementing a simple 4-function expression parser,
# with support for scientific notation, and symbols for e and pi.
# Extended to add exponentiation and simple built-in functions.
# Extended test cases, simplified pushFirst method.
# Removed unnecessary expr.suppress() call (thanks Nathaniel Peterson!), and added Group
# Changed fnumber to use a Regex, which is now the preferred method
# Reformatted to latest pypyparsing features, support multiple and variable args to functions
#
# Copyright 2003-2019 by Paul McGuire
#
from pyparsing import (
    Literal,
    Word,
    Group,
    Forward,
    alphas,
    alphanums,
    Regex,
    ParseException,
    CaselessKeyword,
    Suppress,
    delimitedList,
)
import math
import operator

exprStack = []


def push_first(toks):
    exprStack.append(toks[0])


def push_unary_minus(toks):
    for t in toks:
        if t == "-":
            exprStack.append("unary -")
        else:
            break


bnf = None


def BNF():
    """
    expop   :: '^'
    multop  :: '*' | '/'
    addop   :: '+' | '-'
    integer :: ['+' | '-'] '0'..'9'+
    atom    :: PI | E | real | fn '(' expr ')' | '(' expr ')'
    factor  :: atom [ expop factor ]*
    term    :: factor [ multop factor ]*
    expr    :: term [ addop term ]*
    """
    global bnf
    if not bnf:
        # use CaselessKeyword for e and pi, to avoid accidentally matching
        # functions that start with 'e' or 'pi' (such as 'exp'); Keyword
        # and CaselessKeyword only match whole words
        e = CaselessKeyword("E")
        pi = CaselessKeyword("PI")
        # fnumber = Combine(Word("+-"+nums, nums) +
        #                    Optional("." + Optional(Word(nums))) +
        #                    Optional(e + Word("+-"+nums, nums)))
        # or use provided pyparsing_common.number, but convert back to str:
        # fnumber = ppc.number().addParseAction(lambda t: str(t[0]))
        fnumber = Regex(r"[+-]?\d+(?:\.\d*)?(?:[eE][+-]?\d+)?")
        ident = Word(alphas, alphanums + "_$")
        
        plus, minus, mult, div = map(Literal, "+-*/")
        lpar, rpar = map(Suppress, "()")
        addop = plus | minus
        multop = mult | div
        expop = Literal("^")
        
        expr = Forward()
        expr_list = delimitedList(Group(expr))
        # add parse action that replaces the function identifier with a (name, number of args) tuple
        def insert_fn_argcount_tuple(t):
            fn = t.pop(0)
            num_args = len(t[0])
            t.insert(0, (fn, num_args))
        
        fn_call = (ident + lpar - Group(expr_list) + rpar).setParseAction(
            insert_fn_argcount_tuple
        )
        atom = (
            addop[...]
            + (
                (fn_call | pi | e | fnumber | ident).setParseAction(push_first)
                | Group(lpar + expr + rpar)
            )
        ).setParseAction(push_unary_minus)
        
        # by defining exponentiation as "atom [ ^ factor ]..." instead of "atom [ ^ atom ]...", we get right-to-left
        # exponents, instead of left-to-right that is, 2^3^2 = 2^(3^2), not (2^3)^2.
        factor = Forward()
        factor <<= atom + (expop + factor).setParseAction(push_first)[...]
        term = factor + (multop + factor).setParseAction(push_first)[...]
        expr <<= term + (addop + term).setParseAction(push_first)[...]
        bnf = expr
    return bnf


# map operator symbols to corresponding arithmetic operations
epsilon = 1e-12
opn = {
    "+": operator.add,
    "-": operator.sub,
    "*": operator.mul,
    "/": operator.truediv,
    "^": operator.pow,
}

fn = {
    "sin": math.sin,
    "cos": math.cos,
    "tan": math.tan,
    "exp": math.exp,
    "abs": abs,
    "trunc": int,
    "round": round,
    "sgn": lambda a: -1 if a < -epsilon else 1 if a > epsilon else 0,
    # functionsl with multiple arguments
    "multiply": lambda a, b: a * b,
    "hypot": math.hypot,
    # functions with a variable number of arguments
    "all": lambda *a: all(a),
}

fns = {
    "sin": "math.sin",
    "cos": "math.cos",
    "tan": "math.tan",
    "exp": "math.exp",
    "abs": "abs",
    "trunc": "int",
    "round": "round",
}


def evaluate_stack(s):
    op, num_args = s.pop(), 0
    if isinstance(op, tuple):
        op, num_args = op
    if op == "unary -":
        return -evaluate_stack(s)
    if op in "+-*/^":
        # note: operands are pushed onto the stack in reverse order
        op2 = evaluate_stack(s)
        op1 = evaluate_stack(s)
        return opn[op](op1, op2)
    elif op == "PI":
        return math.pi  # 3.1415926535
    elif op == "E":
        return math.e  # 2.718281828
    elif op in fn:
        # note: args are pushed onto the stack in reverse order
        args = reversed([evaluate_stack(s) for _ in range(num_args)])
        return fn[op](*args)
    elif op[0].isalpha():
        raise Exception("invalid identifier '%s'" % op)
    else:
        # try to evaluate as int first, then as float if int fails
        try:
            return int(op)
        except ValueError:
            return float(op)

def pre_evaluate_stack(s, ps):
    op, num_args = s.pop(), 0
    if isinstance(op, tuple):
        op, num_args = op
    if op == "unary -":
        ps.append([-evaluate_stack(s), 0, 0])
        return 
    if op in "+-*/^":
        # note: operands are pushed onto the stack in reverse order
        op2 = pre_evaluate_stack(s, ps)
        op1 = pre_evaluate_stack(s, ps)
        ps.append([ op, op1, op2])
        return 
    elif op == "PI":
        ps.append([math.pi, 0, 0])  # 3.1415926535
        return 
    elif op == "E":
        ps.append([math.e, 0, 0])  # 2.718281828
        return 
    elif op in fns:
        # note: args are pushed onto the stack in reverse order
        print("s:", s, "op", op)
        args = []
        for x in range(num_args):
            args.append(pre_evaluate_stack(s, ps))
        args.reverse()
        args.insert(fns[op], 0)
        ps.append(args)
        return 
    elif op[0].isalpha():
        return op
    else:
        # return the operand now
        return op


from numba import njit 

@njit
def exec_eqn_pnj(ops, state):
    val1 = state[ops['arg1']]
    val2 = state[ops['arg2']]
    #print("val1 = ", val1, "val2 = ", val2, "op = ", ops[0])
    if ops['op'] == '-':
        result = val1 - val2
        return result # by returning here, we save roughly 45% of the computational time 
    if ops['op'] == '+':
        result = val1 + val2
        return result 
    if ops['op'] == '*':
        result = val1 * val2
        return result         
    return result 

@njit
def exec_eqn_pnjopt(ops, state):
    # these 2 retrievals amount to approx. 35% of exec time.
    val1 = state[ops['arg1']]
    val2 = state[ops['arg2']]
    #return 
    #print("val1 = ", val1, "val2 = ", val2, "op = ", ops[0])
    if ops['op'] == '-':
        result = val1 - val2
    elif ops['op'] == '+':
        result = val1 + val2
    elif ops['op'] == '*':
        result = val1 * val2 
    return result 

    
@njit
def exec_eqn_num(op, ops, state):
    # these 2 retrievals amount to approx. 35% of exec time.
    val1 = state[ops['arg1']]
    val2 = state[ops['arg2']]
    #return 
    #print("val1 = ", val1, "val2 = ", val2, "op = ", ops[0])
    if op == 1:
        result = val1 - val2
    elif op == 2:
        result = val1 + val2
    elif op == 3:
        result = val1 * val2 
    return result 

    
def is_float_digit(n: str) -> bool:
     try:
         float(n)
         return True
     except ValueError:
         return False

import numpy as np
import time
from numba.typed import Dict
from numpy import zeros
from numba import int8, float32, njit, types    # import the types

# allops is created here as a Dict, but really it represents the 
# hdf5 structure, which is allowed to mix string and numbers
# this was just created because I am testing and being sloppy
# but this particular structure will NOT make it into any @njit functions
# and thus can be a more flexible type 
allops = Dict.empty(key_type=types.unicode_type, value_type=types.UnicodeCharSeq(128))
allops["/OBJECTS/RCHRES_0001/discharge_mgd/equation"] = "( (1.0 - consumption - unaccounted_losses) * wd_mgd + discharge_from_gw_mgd)"

# we parse the equation during readuci/pre-processing and break it into njit'able pieces
exprStack[:] = []
results = BNF().parseString(allops["/OBJECTS/RCHRES_0001/discharge_mgd/equation"], parseAll=True)
ps = []
ep = exprStack
pre_evaluate_stack(ep[:], ps)
# need to translate the constants in the equation to hdf5 variables.
# Ex:
#   ps[0] = ['-', '1.0', 'consumption']
#   1.0 is a constant.  The first constant in the discarge_mgd equation 
#   is 1.0, so we add it to the hdf5 as '_c1'
# since numeric values cannot be in the same Dict as strnigs in numba/njit 
# these go directly into state as well as the hdf5 
# then swap the path out for the value 1.0 
# this can be done during parse UCI time since we have all python
#state = Dict.empty(key_type=types.unicode_type, value_type=types.float64)
state = Dict.empty(key_type=types.UnicodeCharSeq(128), value_type=types.float64)
parent_path = "/OBJECTS/RCHRES_0001"
object_path = "/OBJECTS/RCHRES_0001/discharge_mgd"
parent_state_path = "/STATE/RCHRES_0001"
state_path = "/STATE/RCHRES_0001/discharge_mgd"
num_co = 0
ops_path = object_path + "/_ops"
ops_state_path = state_path + "/_ops"
for i in range(0, len(ps) - 1):
    op_name = "_op" + str(i) 
    op_path = ops_path + "/" + op_name 
    op_state_path = ops_state_path + "/" + op_name 
    for j in range(1,3):
        arg_name = "arg" + str(j)
        if ps[i][j] == None: 
            op_str = '_result' # we assume the result from previous step is to be used
            ps[i][j] = '_result' # we assume the result from previous step is to be used
        if is_float_digit(ps[i][j]):
            print(ps[i][j], " is numeric")
            num_co += 1
            co_name = "_c" + str(num_co) 
            # where does the object info reside 
            co_path = op_path + "/" + co_name 
            # where does the numeric value for this reside 
            # this is the value that gets used in the actual njit evaluation functions
            op_state_path = op_state_path + "/" + co_name
            # stash the value here 
            state[op_state_path] = float(ps[i][j])
            op_str = co_name 
            
        else:
            # this is a variable, so we need to get its path 
            # spoofed for now 
            op_str = ps[i][j]
            op_state_path = parent_state_path + "/" + ps[i][j]
        print(op_path + "/" + arg_name + "/path")
        allops[op_path + "/" + arg_name + "/path"] = op_state_path
        allops[op_path + "/" + arg_name] = op_str
    # now set 
    allops[op_path + "/op"] = ps[i][0]
    

        #allops["/OBJECTS/RCHRES_0001/discharge_mgd/_ops"]
        #allops["/OBJECTS/RCHRES_0001/discharge_mgd/_c1"]

# string functions available to us 
#allops["/OBJECTS/RCHRES_0001/discharge_mgd/_ops"] = ps  
#allops["/OBJECTS/RCHRES_0001/discharge_mgd/_ops"]

# use dict 
import numpy as np

#tpvals = Dict.empty(key_type=types.unicode_type, value_type=types.float64)
tpvals = Dict.empty(key_type=types.UnicodeCharSeq(128), value_type=types.float64)
tpops = Dict.empty(key_type=types.unicode_type, value_type=types.UnicodeCharSeq(128))
tpvals['/STATE/RCHRES_0001/discharge_mgd/_c1'] = 1.0 # constants would be populated during equation parsing, if there were 3 constants in the equation they would be _c1, _c2, and _c3
tpvals['/STATE/RCHRES_0001/consumption'] = 0.15 
tpvals['/STATE/RCHRES_0001/consumption'] = 0.15 
tpops['op'] = '-'
tpops['arg1'] = '/STATE/RCHRES_0001/Qin/_c1'
tpops['arg2'] = '/STATE/RCHRES_0001/consumption'

exec_eqn_pnj(tpops, tpvals)

atpops = Dict.empty(key_type=types.unicode_type, value_type=types.UnicodeCharSeq(128))
atpops['op'] = allops['/OBJECTS/RCHRES_0001/discharge_mgd/_ops/_op0/op']
atpops['arg1'] = allops['/OBJECTS/RCHRES_0001/discharge_mgd/_ops/_op0/arg1/path']
atpops['arg2'] = allops['/OBJECTS/RCHRES_0001/discharge_mgd/_ops/_op0/arg2/path']
state['/STATE/RCHRES_0001/consumption'] = 0.15 
exec_eqn_pnj(atpops, state)

import time 
@njit
def iterate_pnj(atpops, state, steps):
    checksum = 0.0
    for step in range(steps):
        checksum += exec_eqn_pnjopt(atpops, state)
        #checksum += exec_eqn_pnj(atpops, state)
        #exec_eqn_pnj(atpops, state)
    return checksum

    
steps = 24 * 365 * 40
#steps = 24 * 365 * 1
start = time.time()
num = iterate_pnj(atpops, state,  steps)
end = time.time()
print(end - start, "seconds")


@njit
def iterate_num(atpop, atpops, state, steps):
    checksum = 0.0
    for step in range(steps):
        checksum += exec_eqn_num(atpop, atpops, state)
    return checksum

# manually set an opnum = 1 (-) for testing 
allops['/OBJECTS/RCHRES_0001/discharge_mgd/_ops/_op0/opnum'] = "1"
atpop = int(allops['/OBJECTS/RCHRES_0001/discharge_mgd/_ops/_op0/opnum'])
start = time.time()
num = iterate_num(atpop, atpops, state, steps)
end = time.time()
print(end - start, "seconds")



@njit
def exec_eqn_nall(op_tokens, state_ix):
    # these 2 retrievals amount to approx. 35% of exec time.
    # allops["/OBJECTS/RCHRES_0001/discharge_mgd/_s_index"] = 1 
    # allops["/OBJECTS/RCHRES_0001/discharge_mgd/_num_ops"] = 1 
    # allops["/OBJECTS/RCHRES_0001/discharge_mgd/_ops/_op1/opi"] = 1 # 1: subtract, 2: add, 3: mult, 4: div 
    # allops["/OBJECTS/RCHRES_0001/discharge_mgd/_ops/_op1/arg1/s_index"] = 2 # pointer to state array
    # allops["/OBJECTS/RCHRES_0001/discharge_mgd/_ops/_op1/arg2/s_index"] = 3 # pointer to state array
    # state_ix[2] = 0.15 # CU fraction state 
    # op_tokens # Executable configs index these by the state_ix variable key which is the global ID, _s_index
    # op_tokens[1] = [1, 1, 2, 3] # [ op class (1 = eqn, 2=list), op type (1-4 for math), arg1 state id, arg2 state id]
    op_class = op_tokens[0] # we actually will use this in the calling function, which will decide what 
                      # next level function to use 
    # todo: see if skipping this temp variable op, val1, val2 setting saves time 
    #op = op_tokens[1]
    #val1 = state_ix[op_tokens[2]]
    #val2 = state_ix[op_tokens[3]]
    result = 0
    #return 
    #print("val1 = ", val1, "val2 = ", val2, "op = ", ops[0])
    #if op == 1:
    if op_tokens[1] == 1:
        #result = val1 - val2
        result = state_ix[op_tokens[2]] - state_ix[op_tokens[3]]
    #elif op == 2:
    elif op_tokens[1] == 2:
        #result = val1 + val2
        result = state_ix[op_tokens[2]] + state_ix[op_tokens[3]]
    #elif op == 3:
    elif op_tokens[1] == 3:
        #result = val1 * val2 
        result = state_ix[op_tokens[2]] * state_ix[op_tokens[3]] 
    return result 


#
op_tokens = Dict.empty(key_type=types.int64, value_type=types.i8[:])
op_tokens[1] = np.asarray([1, 1, 2, 3], dtype="i8")
op_tokens[2] = np.asarray([1, 2, 2, 3], dtype="i8")

state_ix = Dict.empty(key_type=types.int64, value_type=types.float64)
state_ix[2] = 1.0 # value of the variable constant from the equation for discharge_mgd 
state_ix[3] = 0.15 # the value of the variable "consumption" 

exec_eqn_nall(op_tokens[1], state_ix)

@njit
def iterate_nall(op_tokens, state_ix, steps):
    checksum = 0.0
    for step in range(steps):
        state_ix[1] = exec_eqn_nall(op_tokens[1], state_ix)
        checksum += state_ix[1]
        #val = exec_eqn_nall(op_tokens[1], state_ix)
        #state_ix[1] = val
        #checksum += val
    return checksum

start = time.time()
num = iterate_nall(op_tokens, state_ix, steps)
end = time.time()
print(end - start, "seconds")

for i in op_tokens.keys():
    print(i)


# now add simple lookup support 
@njit
def specl_lookup(data_table, keyval, lutype, valcol):
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
    result = specl_lookup(data_table, keyval, lutype, valcol)
    return result
    
# load source from openmi-om/py/XdataMatrix.class.py 
# this is state ix var 3 
# doing a lookup table (like FTABLE) where we are given an arbitrary key column in a table and an arb value 
#     column and we want the output to be the interpolated in the value column according to the key column 
# op is form: op_type, state_ix, dict_ix, mx_type (not used yet), key1_ix, key1_lu_type, key2_ix, key2_lu_type, val_col 
op_tokens[3] = np.asarray([2, 3, 4, 0, 5, 2, 0, 0, 2], dtype="i8") # need to think long and hard about these required tokens
#     notes: 
#            - dict_ix key is NOT always the same as the state_ix key 
#              since we may allow a "matrix accessor" to perform a lookup on another table 
#            - val_col is only used if this is a matrix_accessor and the lookup is a single column 
state_ix[3] = 0.0 # the state var for this matrix accessor (since it is an ftable style lookup)
state_ix[4] = 0.0
# create a psuedo state variable for the storage in the ftable
state_ix[5] = 200000.0
dict_ix = Dict.empty(key_type=types.int64, value_type=types.float32[:,:])
dict_ix[4] = XdataMatrix.parseMatrix("[ [ 0.0, 170.0, 0], [195200.0, 240.0, 8890.6], [204252.8, 241.0, 9301.5], [213736.0, 242.0, 9712.5] ]")


specl_lookup(dict_ix[4], 200000, 2, 2)
exec_tbl_eval(op_tokens[3], state_ix, dict_ix)


@njit
def iterate_all_nall(op_tokens, state_ix, dict_ix, steps):
    checksum = 0.0
    for step in range(steps):
        for i in op_tokens.keys():
            if op_tokens[i][0] == 1:
                state_ix[i] = exec_eqn_nall(op_tokens[i], state_ix)
            elif op_tokens[i][0] == 2:
                state_ix[i] = exec_tbl_eval(op_tokens[i], state_ix, dict_ix)
            checksum += state_ix[i]
    return checksum
    

start = time.time()
num = iterate_all_nall(op_tokens, state_ix, dict_ix, steps)
end = time.time()
print(end - start, "seconds")

    
evaluate_stack(exprStack[:])

if __name__ == "__main__":

    def test(s, expected):
        exprStack[:] = []
        try:
            results = BNF().parseString(s, parseAll=True)
            val = evaluate_stack(exprStack[:])
        except ParseException as pe:
            print(s, "failed parse:", str(pe))
        except Exception as e:
            print(s, "failed eval:", str(e), exprStack)
        else:
            if val == expected:
                print(s, "=", val, results, "=>", exprStack)
            else:
                print(s + "!!!", val, "!=", expected, results, "=>", exprStack)

    test("9", 9)
    test("-9", -9)
    test("--9", 9)
    test("-E", -math.e)
    test("9 + 3 + 6", 9 + 3 + 6)
    test("9 + 3 / 11", 9 + 3.0 / 11)
    test("(9 + 3)", (9 + 3))
    test("(9+3) / 11", (9 + 3.0) / 11)
    test("9 - 12 - 6", 9 - 12 - 6)
    test("9 - (12 - 6)", 9 - (12 - 6))
    test("2*3.14159", 2 * 3.14159)
    test("3.1415926535*3.1415926535 / 10", 3.1415926535 * 3.1415926535 / 10)
    test("PI * PI / 10", math.pi * math.pi / 10)
    test("PI*PI/10", math.pi * math.pi / 10)
    test("PI^2", math.pi ** 2)
    test("round(PI^2)", round(math.pi ** 2))
    test("6.02E23 * 8.048", 6.02e23 * 8.048)
    test("e / 3", math.e / 3)
    test("sin(PI/2)", math.sin(math.pi / 2))
    test("10+sin(PI/4)^2", 10 + math.sin(math.pi / 4) ** 2)
    test("trunc(E)", int(math.e))
    test("trunc(-E)", int(-math.e))
    test("round(E)", round(math.e))
    test("round(-E)", round(-math.e))
    test("E^PI", math.e ** math.pi)
    test("exp(0)", 1)
    test("exp(1)", math.e)
    test("2^3^2", 2 ** 3 ** 2)
    test("(2^3)^2", (2 ** 3) ** 2)
    test("2^3+2", 2 ** 3 + 2)
    test("2^3+5", 2 ** 3 + 5)
    test("2^9", 2 ** 9)
    test("sgn(-2)", -1)
    test("sgn(0)", 0)
    test("sgn(0.1)", 1)
    test("foo(0.1)", None)
    test("round(E, 3)", round(math.e, 3))
    test("round(PI^2, 3)", round(math.pi ** 2, 3))
    test("sgn(cos(PI/4))", 1)
    test("sgn(cos(PI/2))", 0)
    test("sgn(cos(PI*3/4))", -1)
    test("+(sgn(cos(PI/4)))", 1)
    test("-(sgn(cos(PI/4)))", -1)
    test("hypot(3, 4)", 5)
    test("multiply(3, 7)", 21)
    test("all(1,1,1)", True)
    test("all(1,1,1,1,1,0)", False)

    

"""
Test output:
>python fourFn.py
9 = 9 ['9'] => ['9']
-9 = -9 ['-', '9'] => ['9', 'unary -']
--9 = 9 ['-', '-', '9'] => ['9', 'unary -', 'unary -']
-E = -2.718281828459045 ['-', 'E'] => ['E', 'unary -']
9 + 3 + 6 = 18 ['9', '+', '3', '+', '6'] => ['9', '3', '+', '6', '+']
9 + 3 / 11 = 9.272727272727273 ['9', '+', '3', '/', '11'] => ['9', '3', '11', '/', '+']
(9 + 3) = 12 [['9', '+', '3']] => ['9', '3', '+']
(9+3) / 11 = 1.0909090909090908 [['9', '+', '3'], '/', '11'] => ['9', '3', '+', '11', '/']
9 - 12 - 6 = -9 ['9', '-', '12', '-', '6'] => ['9', '12', '-', '6', '-']
9 - (12 - 6) = 3 ['9', '-', ['12', '-', '6']] => ['9', '12', '6', '-', '-']
2*3.14159 = 6.28318 ['2', '*', '3.14159'] => ['2', '3.14159', '*']
3.1415926535*3.1415926535 / 10 = 0.9869604400525172 ['3.1415926535', '*', '3.1415926535', '/', '10'] => ['3.1415926535', '3.1415926535', '*', '10', '/']
PI * PI / 10 = 0.9869604401089358 ['PI', '*', 'PI', '/', '10'] => ['PI', 'PI', '*', '10', '/']
PI*PI/10 = 0.9869604401089358 ['PI', '*', 'PI', '/', '10'] => ['PI', 'PI', '*', '10', '/']
PI^2 = 9.869604401089358 ['PI', '^', '2'] => ['PI', '2', '^']
round(PI^2) = 10 [('round', 1), [['PI', '^', '2']]] => ['PI', '2', '^', ('round', 1)]
6.02E23 * 8.048 = 4.844896e+24 ['6.02E23', '*', '8.048'] => ['6.02E23', '8.048', '*']
e / 3 = 0.9060939428196817 ['E', '/', '3'] => ['E', '3', '/']
sin(PI/2) = 1.0 [('sin', 1), [['PI', '/', '2']]] => ['PI', '2', '/', ('sin', 1)]
10+sin(PI/4)^2 = 10.5 ['10', '+', ('sin', 1), [['PI', '/', '4']], '^', '2'] => ['10', 'PI', '4', '/', ('sin', 1), '2', '^', '+']
trunc(E) = 2 [('trunc', 1), [['E']]] => ['E', ('trunc', 1)]
trunc(-E) = -2 [('trunc', 1), [['-', 'E']]] => ['E', 'unary -', ('trunc', 1)]
round(E) = 3 [('round', 1), [['E']]] => ['E', ('round', 1)]
round(-E) = -3 [('round', 1), [['-', 'E']]] => ['E', 'unary -', ('round', 1)]
E^PI = 23.140692632779263 ['E', '^', 'PI'] => ['E', 'PI', '^']
exp(0) = 1.0 [('exp', 1), [['0']]] => ['0', ('exp', 1)]
exp(1) = 2.718281828459045 [('exp', 1), [['1']]] => ['1', ('exp', 1)]
2^3^2 = 512 ['2', '^', '3', '^', '2'] => ['2', '3', '2', '^', '^']
(2^3)^2 = 64 [['2', '^', '3'], '^', '2'] => ['2', '3', '^', '2', '^']
2^3+2 = 10 ['2', '^', '3', '+', '2'] => ['2', '3', '^', '2', '+']
2^3+5 = 13 ['2', '^', '3', '+', '5'] => ['2', '3', '^', '5', '+']
2^9 = 512 ['2', '^', '9'] => ['2', '9', '^']
sgn(-2) = -1 [('sgn', 1), [['-', '2']]] => ['2', 'unary -', ('sgn', 1)]
sgn(0) = 0 [('sgn', 1), [['0']]] => ['0', ('sgn', 1)]
sgn(0.1) = 1 [('sgn', 1), [['0.1']]] => ['0.1', ('sgn', 1)]
foo(0.1) failed eval: invalid identifier 'foo' ['0.1', ('foo', 1)]
round(E, 3) = 2.718 [('round', 2), [['E'], ['3']]] => ['E', '3', ('round', 2)]
round(PI^2, 3) = 9.87 [('round', 2), [['PI', '^', '2'], ['3']]] => ['PI', '2', '^', '3', ('round', 2)]
sgn(cos(PI/4)) = 1 [('sgn', 1), [[('cos', 1), [['PI', '/', '4']]]]] => ['PI', '4', '/', ('cos', 1), ('sgn', 1)]
sgn(cos(PI/2)) = 0 [('sgn', 1), [[('cos', 1), [['PI', '/', '2']]]]] => ['PI', '2', '/', ('cos', 1), ('sgn', 1)]
sgn(cos(PI*3/4)) = -1 [('sgn', 1), [[('cos', 1), [['PI', '*', '3', '/', '4']]]]] => ['PI', '3', '*', '4', '/', ('cos', 1), ('sgn', 1)]
+(sgn(cos(PI/4))) = 1 ['+', [('sgn', 1), [[('cos', 1), [['PI', '/', '4']]]]]] => ['PI', '4', '/', ('cos', 1), ('sgn', 1)]
-(sgn(cos(PI/4))) = -1 ['-', [('sgn', 1), [[('cos', 1), [['PI', '/', '4']]]]]] => ['PI', '4', '/', ('cos', 1), ('sgn', 1), 'unary -']
"""
