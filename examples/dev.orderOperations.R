# install.packages('https://github.com/HARPgroup/openmi-om/raw/master/R/openmi.om_0.0.0.9105.tar.gz', repos = NULL, type="source")

library("rjson")
library("hydrotools")
library("openmi.om")

source("https://raw.githubusercontent.com/HARPgroup/hydro-tools/master/VAHydro-2.0/find_name.R")
source("/var/www/R/config.R")
# Create datasource
ds <- RomDataSource$new("https://deq1.bse.vt.edu/d.dh", 'restws_admin')
ds$get_token(rest_pw)
model_prop <- RomProperty$new(ds,list(featureid = 71807, entity_type = 'dh_feature', propcode = 'vwp-1.0'), TRUE)
src_json_node <- paste('https://deq1.bse.vt.edu/d.dh/node/62', model_prop$pid, sep="/")
load_txt <- ds$auth_read(src_json_node, "text/json", "")
load_objects <- fromJSON(load_txt)
model <- load_objects[[model_prop$propname]]

# load the open mi data format
pump_cfs_od <- model$pump_cfs
# create an equation from this, TBD: move to loader function on object
pump_cfs <- openmi_om_load(pump_cfs_od);

# TBD - translate from PHP, and also restructure to be more modular and readable 
function orderOperations() {
  
  $dependents = array();
  $independents = array();
  $sub_queue = array();
  $execlist = array();
  // compile a list of independent and dependent variables
  // @todo: rvars on subcomps are explicit independent inputs to subcomps that are not yet handled
  //        wvars are explicit outputs from subcomps that are often used by other comps
  //        We also need to check to see if we are putting things in vars that should not be?
    //        vars is a catchall used by equations which is equivalent to rvars but I *think*
    //        vars has become a place for both rvars and wvars which might lead to unpredictable behavior
  foreach (array_keys($this->processors) as $thisinput) {
    foreach ($this->processors[$thisinput]->wvars as $wv) {
      $independents[$this->processors[$thisinput]->getParentVarName($wv)] = $thisinput;
    }
    array_push($dependents, $thisinput);
  }
  if ($this->debug) {
    $this->logDebug("<b>Ordering Operations for $this->name</b><br> ");
  }
  $this->outstring .= "Ordering Operations for $this->name\n";
  // now check the list of independent variables for each processor,
  // if none of the variables are in the current list of dependent variables
  // put it into the execution stack, remove from queue
  $queue = $dependents;
  // sort those with non-zero hierarchy settings, placing all <0 hierarchy in order on the bottom of the queue (early)
  // then place all of those later
  $preexec = array();
  $postexec = array();
  $nonhier = array();
  $hiersort = array();
  foreach ($queue as $thisel) {
    array_push($hiersort, $thisel);
  }
  sort($hiersort);
  foreach ($hiersort as $thisel) {
    $hier = $this->processors[$thisel]->exec_hierarch;
    if ($hier < 0) {
      $preexec[$thisel] = $hier;
    } else {
      if ($this->processors[$thisel]->exec_hierarch > 0) {
        $postexec[$thisel] = $hier;
      } else {
        array_push($nonhier, $thisel);
      }
    }
  }
  asort($preexec);
  $preexec = array_keys($preexec);
  asort($postexec);
  $postexec = array_keys($postexec);
  $queue = $nonhier;
  $this->logDebug("Beginning Queue \n");
  $this->logDebug($queue);
  $this->logDebug("Beginning independents \n");
  $this->logDebug($independents);
  $i = 0;
  $dbc = $this->debug;
  $this->debug = 0;
  while (count($queue) > 0) {
    $thisdepend = array_shift($queue);
    $pvars = $this->processors[$thisdepend]->vars;
    //$watchlist = array('impoundment', 'local_channel');
    //$this->debug = in_array( $this->processors[$depend]->name, $watchlist) ? 1 : 0;
    if ($this->debug) {
      $this->logDebug("Checking $thisdepend variables \n");
      $this->logDebug($pvars);
      $this->logDebug(" <br>\n in ");
      $this->logDebug($queue);
      $this->logDebug("<br>\n");
    }
    $numdepend = $this->array_in_array($pvars, $queue);
    if (!$numdepend) {
      array_push($execlist, $thisdepend);
      $i = 0;
      if ($this->debug) {
        $this->logDebug("Not found, adding $thisdepend to execlist.<br>\n");
      }
      // remove it from the derived var list if it exists there 
      while ($dkey = array_search($thisdepend, $independents)) {
        unset($independents[$dkey]);
      }
    } else {
      // put it back on the end of the stack
      if ($this->debug) {
        $this->logDebug("Found.<br>\n");
      }
      array_push($queue, $thisdepend);
    }
    $i++;
    // should try to sort them out by the number of unsatisfied dependencies,
    // adding those with 1 dependency first
    if ( ($i > count($queue)) and (count($queue) > 0)) {
      # we have reached an impasse, since we cannot currently
      # solve simultaneous variables, we just put all remaining on the
      # execlist and hope for the best
      # a more robust approach would be to determine which elements are in a circle,
      # and therefore producing a bottleneck, as other variables may not be in a circle
      # themselves, but may depend on the output of objects that are in a circle
      # then, if we add the circular variables to the queue, we may be able to continue
      # trying to order the remaining variables
      
      # first, create a list of execution hierarchies and compids
      $hierarchy = array();
      foreach ($queue as $thisel) {
        $hierarchy[$thisel] = $this->processors[$thisel]->exec_hierarch;
      }
      # sort in reverse order of hierarchy
      # then, look at exec_hierarch property, if the first element is higher priority than the lowest in the stack
      # pop it off the list, and add it to the queue
      # then, after doing that, we can go back, set $i = 0, and try to loop through again,
      arsort($hierarchy);
      $keyar = array_keys($hierarchy);
      if ($this->debug) {
        $this->logDebug("Cannot determine sequence of remaining variables, searching manual execution hierarchy setting.<br>\n");
      }
      $firstid = $keyar[0];
      $fh = $hierarchy[$firstid];
      $mh = min(array_values($hierarchy));
      if ($this->debug) {
        $this->logDebug("Highest hierarchy value = $fh, Lowest = $mh.<br>\n");
      }
      if ($fh > $mh) {
        # pop off and resume trying to sort them out
        $newqueue = array_diff($queue, array($firstid) );
        array_push($execlist, $firstid);
        $i = 0;
        if ($this->debug) {
          $this->logDebug("Elelemt " . $firstid . ", with hierarchy " . $hierarchy[$firstid] . " added to execlist.<br>\n");
        }
        $queue = $newqueue;
      } else {
        
        if ($this->debug) {
          $this->logDebug("Can not determine linear sequence for the remaining variables. <br>\n");
          $this->logDebug($queue);
          $this->logDebug("<br>\nDefaulting to order by number of unsatisfied dependencies.<br>\n");
          $this->logDebug("<br>\nHoping their execution order does not matter!.<br>\n");
        }
        foreach ($queue as $lastcheck) {
          $pvars = $this->processors[$lastcheck]->vars;
          $numdepend = $this->array_in_array($pvars, $queue);
          $dependsort[$lastcheck] = $numdepend;
        }
        asort($dependsort);
        if ($this->debug) {
          $this->logDebug("Remaining variable sort order: \n");
          $this->logDebug($dependsort);
        }
        $numdepend = $this->array_in_array($pvars, array_keys($dependsort));
        $newexeclist = array_merge($execlist, $queue);
        $execlist = $newexeclist;
        break;
      }
    }
  }
  $this->debug = $dbc;
  $hiersort = array_merge($preexec, $execlist, $postexec);
  
  
  $this->logDebug("Final Queue \n");
  $this->logDebug($queue);
  $this->logDebug("Final independents \n");
  $this->logDebug($independents);
  $this->logDebug("Pre-exec list: \n");
  $this->logDebug($preexec);
  $this->logDebug("Dependency ordered: \n");
  $this->logDebug($hiersort);
  $this->logDebug("Post-exec list:  \n");
  $this->logDebug($postexec);
  
  $this->outstring .= "Ordering Operations\n";
  $this->outstring .= "Independents Remaining: " . print_r($independents,1) . "\n";
  $this->outstring .= "Pre-exec list: " . print_r($preexec,1) . "\n";
  $this->outstring .= "To Be ordered: " . print_r($nonhier,1) . "\n";
  $this->outstring .= "Dependency ordered: " . print_r($execlist,1) . "\n";
  $this->outstring .= "Post-exec list: " . print_r($postexec,1) . "\n";
  $this->outstring .= "Sorted: " . print_r($hiersort,1) . "\n";
  $this->execlist = $hiersort;
}
