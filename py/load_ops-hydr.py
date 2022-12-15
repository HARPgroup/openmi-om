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
state[hydr_ix['O1']] = outdgt[0]
state[hydr_ix['O2']] = outdgt[1]
state[hydr_ix['O3']] = outdgt[2]
# after returning from specl()
outdgt[:] = [state[hydr_ix['O1']], state[hydr_ix['O2']], state[hydr_ix['O3']] ]