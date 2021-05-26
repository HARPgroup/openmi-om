# misc test code for object model dev



# this seems to work
obj$components$whtf_diff$parse_openmi(obj_json$whtf_diff$equation)
# but this was not parsed right as part of the batch.
obj$components$whtf_diff$equation
#
elem_info <- obj_json$whtf_diff
eq_test <- openmi.om.equation$new(elem_info, format = 'openmi')
eq_test$set_prop('equation', elem_info[['equation']], 'openmi')
eq_test$set_prop('equation', elem_info['equation'], 'openmi')
i = 'equation'
i = names(elem_info)[4]
eq_test$set_prop(as.character(i), elem_info[[i]], 'openmi')



#
obj <- openmi.om.base$new(list(name='test'))
wyb <- openmi.om.equation$new(list(name='wyb', equation='water.year(timer$thistime) - 1'));
#wyb$equation = "water.year(timer$thistime) - 1";
obj$add_component(wyb)
