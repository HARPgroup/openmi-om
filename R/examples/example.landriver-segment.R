library(httr);
save_directory <- "/var/www/html/files/fe/plots"
#----------------------------------------------
site <- "http://deq2.bse.vt.edu/d.alpha"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
basepath='/var/www/R';
source(paste(basepath,'config.local.private',sep='/'));
source(paste(hydro_tools,"VAHydro-2.0/rest_functions.R", sep = "/")); 
source(paste(hydro_tools,"VAHydro-1.0/fn_vahydro-1.0.R", sep = "/"));  
source(paste(hydro_tools,"LowFlow/fn_iha.R", sep = "/"));  
#retrieve rest token
source(paste(hydro_tools,"auth.private", sep = "/"));#load rest username and password, contained in auth.private file
token <- rest_token(site, token, rest_uname, rest_pw);
options(timeout=120); # set timeout to twice default level to avoid abort due to high traffic

lrseg = "A51121_OR2_8130_7900";
hydrocode = lrseg;
ftype = 'cbp532_lrseg'; # nhd_huc8, nhd_huc10, vahydro
inputs <- list (
  hydrocode = hydrocode,
  bundle = 'landunit',
  ftype = ftype
)
#property dataframe returned
feature = FALSE;
odata <- getFeature(inputs, token, site, feature);

hydroid <- as.numeric(as.character(odata[1,]$hydroid));
fname <- as.character(odata[1,]$name );
print(paste("Retrieved hydroid",hydroid,"for", fname,lrseg, sep=' '));

# get the p5.3.2, scenario  model segment attached to this river feature
inputs <- list(
  varkey = "om_model_element",
  featureid = hydroid,
  entity_type = "dh_feature",
  propcode = "vahydro-1.0"
)
model <- getProperty(inputs, site, model)
model$propvalue = 2.0
inputs$propvalue = 2.0
retval = postProperty(inputs,fxn_locations,base_url=site,prop)

# now, retrieve august low flow property if set
query_luhist <- list(
  varkey = "om_class_DataMatrix",
  propname = 'landuse_historic',
  featureid = as.integer(as.character(model$pid)),
  entity_type = "dh_properties"
)
prop_luhist <- getProperty(query_luhist, site, landuse_historic)
table_luhist = jsonlite::unserializeJSON(prop_luhist$field_dh_matrix)


# save edits
# postProperty(alfprop,fxn_locations,base_url = site,alfprop) ;

