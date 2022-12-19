# load specl objects in HYDR

# *****************************
# set this up at the beginning, we will use this to find relevant operations 
# - for now it is ignored, as we assume that during demo runs all ops get exec'd
root = "/STATE/RCHRES_R001" # any objects that are connected to this object should be loaded 
domain = "/STATE/RCHRES_R001/HYDR" # any objects that are connected to this object should be loaded 
# objects below this path should be in the state Dict and thus don't need to be loaded

# *****************************
# BEFORE CALLING the step do this:
# get a list of keys for all hydr state variables
hydr_state = ["DEP","IVOL","O1","O2","O3","OVOL1","OVOL2","OVOL3","PRSUPY","RO","ROVOL","SAREA","TAU","USTAR","VOL","VOLEV"]
hydr_ix = Dict.empty(key_type=types.unicode_type, value_type=types.int64)
for i in hydr_state:
    var_path = f'{domain}/{i}'
    hydr_ix[i] = set_state(state_ix, state_paths, var_path, 0.0)


# *****************************
# At the beginning of each step do this:
# before calling specl()
# Can we rewrite:
#   state[hydr_ix['O1']] = outdgt[0]
#   state[hydr_ix['O2']] = outdgt[1]
#   state[hydr_ix['O3']] = outdgt[2]
# as:
# state[hydr_ix['O1']], state[hydr_ix['O2']], state[hydr_ix['O3']] = outdgt[0], outdgt[1], outdgt[2]
# pointers to the state variables in question
o1_ix, o2_ix, o3_ix = hydr_ix['O1'], hydr_ix['O2'], hydr_ix['O3']
# contrast performance of this:
state_ix[hydr_ix['O1']], state_ix[hydr_ix['O2']], state_ix[hydr_ix['O3']] = outdgt[0], outdgt[1], outdgt[2]
# slower than this:
state_ix[o1_ix], state_ix[o2_ix], state_ix[o3_ix] = outdgt[0], outdgt[1], outdgt[2]



# after returning from specl()
# is this option: 
outdgt[:] = [state_ix[hydr_ix['O1']], state_ix[hydr_ix['O2']], state_ix[hydr_ix['O3']] ]
# slower than this one?:
outdgt[:] = [ state_ix[o1_ix], state_ix[o2_ix], state_ix[o3_ix] ]


def hydr_get_ix(state_ix, state_paths, domain):
    # get a list of keys for all hydr state variables
    hydr_state = ["DEP","IVOL","O1","O2","O3","OVOL1","OVOL2","OVOL3","PRSUPY","RO","ROVOL","SAREA","TAU","USTAR","VOL","VOLEV"]
    hydr_ix = Dict.empty(key_type=types.unicode_type, value_type=types.int64)
    for i in hydr_state:
        #var_path = f'{domain}/{i}'
        var_path = domain + "/" + i
        hydr_ix[i] = set_state(state_ix, state_paths, var_path, 0.0)
    return hydr_ix


# test iterate hydr

from pandas import DataFrame
df = DataFrame()
df[0] = 0.0
df[1] = 0.0
df[2] = 0.0
OUTDGT = df.to_numpy()
steps = 40 * 365 * 24


# add to hydr() (not _hydr_())
hydr_ix = hydr_get_ix(state_ix, state_paths, domain)


@njit
def iterate_hydr(op_tokens, state_ix, dict_ix, ts_ix, steps, OUTDGT, hydr_ix):
    outdgt = zeros(3)
    outdgt[:] = OUTDGT[0,:]
    
    o1_ix, o2_ix, o3_ix = hydr_ix['O1'], hydr_ix['O2'], hydr_ix['O3']
    for step in range(steps):
        # this:
        #state_ix[hydr_ix['O1']], state_ix[hydr_ix['O2']], state_ix[hydr_ix['O3']] = outdgt[0], outdgt[1], outdgt[2]
        # is 0.3 seconds slower on a 40 year hourly sim than this:
        state_ix[o1_ix], state_ix[o2_ix], state_ix[o3_ix] = outdgt[0], outdgt[1], outdgt[2]
        pre_step_model(op_tokens, state_ix, dict_ix, ts_ix)
        step_model(op_tokens, state_ix, dict_ix, ts_ix, step)
        #outdgt[:] = [ state_ix[hydr_ix['O1']], state_ix[hydr_ix['O2']], state_ix[hydr_ix['O3']] ]
        outdgt[:] = [ state_ix[o1_ix], state_ix[o2_ix], state_ix[o3_ix] ]
    return 


start = time.time()
iterate_hydr(op_tokens, state_ix, dict_ix, ts_ix, steps, OUTDGT, hydr_ix)
end = time.time()
print(end - start, "seconds")

# not yet working below step_hydr()
@njit
def step_hydr(op_tokens, state_ix, dict_ix, ts_ix, step, hydr_ix):
    o1_ix, o2_ix, o3_ix = hydr_ix['O1'], hydr_ix['O2'], hydr_ix['O3']
    outdgt[:] = [ state_ix[o1_ix], state_ix[o2_ix], state_ix[o3_ix] ]

