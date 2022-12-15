op_tokens, state_paths, state_ix, dict_ix = init_sim_dicts()
river = modelObject('RCHRES_R001', state_ix, state_paths, dict_ix)
river.state_path = specl_state_path('RCHRES', 1)
river.register_path()

river.add_input("Qin", f'{river.state_path}/HYDR/IVOL')
# alternative, using TIMESERIES: 
# river.inputs["Qin"] = ["/TIMESERIES/TS011"]
# river.add_input("ps_mgd", "/TIMESERIES/TS3000")

facility = modelObject('facility', state_ix, state_paths, dict_ix)
facility.container = river
facility.make_state_path()
facility.register_path()

Qintake = Equation('Qintake', state_ix, state_paths, dict_ix)
Qintake.container = facility
Qintake.make_state_path()
Qintake.register_path()

river.find_var_path("Qin")
Qintake.find_var_path("Qin")
Qintake.equation = "Qin * 1.21"
Qintake.tokenize_ops() 
Qintake.tokenize_vars()

flowby = Equation('flowby', state_ix, state_paths, dict_ix)
flowby.container = facility
flowby.equation = "Qintake * 0.9"
flowby.tokenize_ops() 
flowby.tokenize_vars()

wd_mgd = Equation('demand_mgd', state_ix, state_paths, dict_ix)
wd_mgd.container = facility
wd_mgd.equation = "3.0"
wd_mgd.tokenize_ops() 
wd_mgd.tokenize_vars()


