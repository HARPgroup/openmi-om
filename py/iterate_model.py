
@njit
def iterate_models(op_tokens, state_ix, dict_ix, ts_ix, steps):
    checksum = 0.0
    for step in range(steps):
        pre_step_model(op_tokens, state_ix, dict_ix, ts_ix)
        step_model(op_tokens, state_ix, dict_ix, ts_ix, step)
    return checksum

@njit
def pre_step_model(op_tokens, state_ix, dict_ix, ts_ix):
    for i in op_tokens.keys():
        if op_tokens[i][0] == 1:
            return False
        elif op_tokens[i][0] == 2:
            return False
        elif op_tokens[i][0] == 3:
            return False
        elif op_tokens[i][0] == 4:
            return False
        elif op_tokens[i][0] == 5:
            return False
    return

@njit 
def step_model(op_tokens, state_ix, dict_ix, ts_ix, step):
    for i in op_tokens.keys():
        if op_tokens[i][0] == 1:
            state_ix[i] = exec_eqn(op_tokens[i], state_ix)
        elif op_tokens[i][0] == 2:
            state_ix[i] = exec_tbl_eval(op_tokens[i], state_ix, dict_ix)
        elif op_tokens[i][0] == 3:
            step_model_link(op_tokens[i], state_ix, ts_ix, step)
        elif op_tokens[i][0] == 4:
            return False
        elif op_tokens[i][0] == 5:
            return False
    return 

"""
# manually test models with this:
if op_tokens[i][0] == 1:
    state_ix[i] = exec_eqn(op_tokens[i], state_ix)
elif op_tokens[i][0] == 2:
    state_ix[i] = exec_tbl_eval(op_tokens[i], state_ix, dict_ix)
elif op_tokens[i][0] == 3:
    step_model_link(op_tokens[i], state_ix, ts_ix, step)
elif op_tokens[i][0] == 4:
    print("Skip type", op_tokens[i][0])
elif op_tokens[i][0] == 5:
    print("Skip type", op_tokens[i][0])
"""
