#install.packages('https://github.com/HARPgroup/openmi-om/raw/master/R/openmi.om_0.0.0.9105.tar.gz', repos = NULL, type="source")

library("rjson")
library("hydrotools")
library("openmi.om")

source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/VAHydro-2.0/find_name.R")
basepath = "/var/www/R"
source("/var/www/R/config.R")
# Create datasource
ds <- RomDataSource$new("http://deq1.bse.vt.edu/d.dh", 'restws_admin')
ds$get_token(rest_pw)

# feature hydroid
hydroid <- 475973

model_prop <- RomProperty$new(ds,list(featureid = hydroid, entity_type = 'dh_feature', propcode = 'vahydro-1.0'), TRUE)
src_json_node <- paste('https://deq1.bse.vt.edu/d.dh/node/62', model_prop$pid, sep="/")
load_txt <- ds$auth_read(src_json_node, "text/json", "")
load_objects <- fromJSON(load_txt)
model_json <- load_objects[[model_prop$propname]]
model <-  openmi_om_load(model_json)
model$init()

om.trace.vars <- function (
  model, i, max_depth = 1, depth = 0, traced = c()
  ) {
  depth = depth + 1
  message(paste("examining",i))
  # note, this only finds direct components
  # other things, like broadcasts local vars, and
  # auto-written matrix vars and inputs need to be
  # found as well.  This may actually be doable with
  # a model method?
  thiscomp <- model$components[[i]]
  if (is.null(thiscomp)) {
    message(paste("Could not locate", i))
    return(traced)
  }
  compvars <- thiscomp$vars
  if (is.null(compvars)) {
    message("Component has no variable inputs... Skipping.")
    return(traced)
  }
  if (depth <= max_depth) {
    # try to locate each variable, message if missing
    for (j in compvars) {
      traced <- cbind(traced,om.trace.vars(model, j, max_depth, depth + 1, traced))
    }
  } else {
    return(traced)
  }

}


compnames <- names(model$components)
finished <- FALSE
i <- "wd_mgd"
om.trace.vars(model, "Qintake")
