op_tokens, state_paths, state_ix, dict_ix, ts_ix = init_sim_dicts()
modelObject.op_tokens, modelObject.state_paths, modelObject.state_ix, modelObject.dict_ix = (op_tokens, state_paths, state_ix, dict_ix)

river = modelObject('RCHRES_R001')
river.state_path = specl_state_path('RCHRES', 1)
river.register_path()

river.add_input("Qin", f'{river.state_path}/HYDR/IVOL')
# alternative, using TIMESERIES: 
# river.inputs["Qin"] = ["/TIMESERIES/TS011"]
# river.add_input("ps_mgd", "/TIMESERIES/TS3000")

facility = modelObject('facility', river)
facility.make_state_path()
facility.register_path()

Qintake = Equation('Qintake', facility, "Qin * 1.21")
Qintake.make_state_path()
Qintake.register_path()
Qintake.tokenize()

flowby = Equation('flowby', facility, "Qintake * 0.9")
flowby.register_path()
flowby.tokenize()

wd_mgd = Equation('wd_mgd', facility, "3.0 + 0.0")
wd_mgd.register_path()
wd_mgd.tokenize() 

import random
# add a series of rando equations 
c=["flowby", "wd_mgd", "Qintake"]
for k in range(100):
    eqn = str(25*random.random()) + " * " + c[round((2*random.random()))]
    newq = Equation('eq' + str(k), facility, eqn)
    newq.register_path()
    newq.tokenize()
    newq.add_op_tokens()

# now connect the wd_mgd back to the river with a direct link.  
# This is not how we'll do it for most simulations as there may be multiple inputs but will do for now
hydr = modelObject('HYDR', river)
hydr.register_path()
O1 = modelLinkage('O1', hydr, wd_mgd.state_path, 2)
O1.register_path()
O1.tokenize() 


river.add_op_tokens()
facility.add_op_tokens()
Qintake.add_op_tokens()
flowby.add_op_tokens()
wd_mgd.add_op_tokens()
O1.add_op_tokens()

step_model(op_tokens, state_ix, dict_ix, ts_ix, 1)

steps=40*365*24
start = time.time()
num = iterate_models(op_tokens, state_ix, dict_ix, ts_ix, steps)
end = time.time()
print(end - start, "seconds")



