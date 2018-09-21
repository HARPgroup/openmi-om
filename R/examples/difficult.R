#library(pander);
library(httr);
save_directory <- "/var/www/html/files/fe/plots"
#----------------------------------------------
site <- "http://deq1.bse.vt.edu/d.dh"    #Specify the site of interest, either d.bet OR d.dh
#----------------------------------------------
# Load Libraries
fxn_locations = '/var/www/R/r-dh-ecohydro/Analysis';
source(paste(fxn_locations,"fn_vahydro-1.0.R", sep = "/"));  
source(paste(fxn_locations,"fn_iha.R", sep = "/"));  

library(dataRetrieval);
library(hydroTSM);

#elid = 339865; # Frederick Co pump-store
#elid = 209793; # Bath Co
#elid = 252285; # Smith River Martinsville
elid = 340073; 
# Difficult Run - 339991 - 30.45 / 58.3 - Qmean 66.1 cfs 
# * Martins Lake - 340114 - 0.5 sqmi
# * Lake Audubon - 340098 - 0.1 / 2.37 sqmi
# ** Lake Thoreau - 340116 - 0.57 - 2.37
# ** NOTE: Audubon & THoreau both report 2.37 sqmi
#    but only sum to 0.67 SQMI, so, -1.6 s- qmi DA
# * Lake Fairfax - 340106 - 2.89 / 4.22 sqmi
# ** Lake Anne - 340118 - 0.91 / 4.22
# ** NOTE: DA disagrees, 4.22 > 2.89 + 0.91
# * Piney Run - 340102 - 3.65 / 4.05
# ** Pond 2 - 340100 - 0.0545 / 4.05
# ** NOTE: DA disagrees, 4.05 > 3.65 + 0.0545
# * Lower Timber Lake - 340128 - 2.3228 / 2.42 
# ** NOTE: DA disagrees, NO TRIBS, so 2.42 > 2.3228
# * Pond 22 - 340073 - 0.32 / 1.45 
# ** Pond 32 - 340136 - 0.59 / 0.59
# ** NOTE: DA disagrees, 1.45 > 0.32  + 0.59
#runid = 232018; # 2001-2005 run
runid = 998;
runzero = 900;
datamode = 'file'; 
# datamode = 'file' or 'variable'.  
# file is great if downloads are not too big, then variable is needed
# get a single variable in a timeseries summarized by day, keyed by thisdate
#
#plot(elevs);
# get all data from the run file, keyed by timestamp (at whatever timestep model is run)

if (datamode == 'file') {
  dat <- fn_get_runfile(elid, runid);
} else {
  # need to assemble separately, takes time for short runs but prevents time outs in longer runs
  impoundment_lake_elev <- fn_get_rundata(elid, runid, "impoundment_lake_elev");
  Runit <- fn_get_rundata(elid, runid, "cbp_runoff_Runit");
  thisdate = zoo(
    as.character(time(impoundment_lake_elev)), 
    order.by = time(impoundment_lake_elev)
  );
  Qout <- fn_get_rundata(elid, runid, "Qout");
  impoundment_Qin <- fn_get_rundata(elid, runid, "impoundment_Qin");
  Qzero <- fn_get_rundata(
    elid, runzero, "Qout", 
    startdate = min(thisdate), enddate = max(thisdate)
  );
  zRunit <- fn_get_rundata(
    elid, runzero, "cbp_runoff_Runit", 
    startdate = min(thisdate), enddate = max(thisdate)
  );
  dat <- cbind(
    thisdate,
    impoundment_lake_elev, 
    Qout,
    impoundment_Qin,
    Qzero,
    Runit,
    zRunit
  );
}
Qout = aggregate(as.numeric(dat$impoundment_Qin), as.list(dat$thisdate), FUN = mean);
Qusgs = aggregate(as.numeric(dat$Qusgs), as.list(dat$thisdate), FUN = mean);
Qtrib = aggregate(as.numeric(dat$Qtrib), as.list(dat$thisdate), FUN = mean);

ymax = ceiling(max(as.numeric(dat$impoundment_Qin)));
emax = ceiling(max(as.numeric(dat$impoundment_lake_elev)));
plot(dat$Qout,ylim=c(0,ymax))
par(pch=22, col="green") # plotting symbol and color 
points(dat$impoundment_Qin)
par(pch=22, col="black") # plotting symbol and color 
points(dat$impoundment_Qout)
#fdc(dat$Qout, main="Flow Duration", log='', xlab="Flow Exceedence",
#    ylab="Q cfs", verbose=FALSE);

#as.numeric(as.character( dat$Qout ))
# For some reason we need to convert these numeric fields to char, then to number
# before sending to zoo since their retrieval is classifying them as factors instead of nums
# now there may be away to get around that but...
#flows <- zoo(as.numeric(as.character( dat$Qout )), order.by = dat$thisdate);
#fn_iha_7q10(flows)
#fn_iha_mlf(flows,8)
#g2 <- group2(flows);

# plot drawdown
par(las=2)
plot(dat$impoundment_lake_elev, ylim = c(0.0, emax));
plot(dat$impoundment_Qin, ylim = c(0.0, ymax));
par(pch=22, col="green") # plotting symbol and color 
points(dat$impoundment_Qout);
# or at a gage:
par(pch=22, col="blue") # plotting symbol and color 
points(dat$Qusgs);

wudat <- window(dat, start = as.Date("1997-05-01"), end = as.Date("1997-05-28"));
plot(wudat$impoundment_Qin,ylim=c(0,ymax))
par(pch=22, col="green") # plotting symbol and color 
points(wudat$Qout);
par(pch=22, col="orange") # plotting symbol and color 
points(wudat$Qzero);
# or at a gage:
par(pch=22, col="blue") # plotting symbol and color 
points(wudat$Qusgs);
par(pch=22, col="green") # plotting symbol and color 
points(wudaily$x);

for(i in unique(dat$year)) { 
  ys <- paste(i, "-03-01", sep='');
  ye <- paste(i, "-05-31", sep='');
  yrdat <- window(dat, start = as.Date(ys), end = as.Date(ye));
  pdmax = ceiling(max(as.numeric(yrdat$impoundment_Qin)));
  qout = aggregate(as.numeric(yrdat$impoundment_Qin), as.list(yrdat$thisdate), FUN = mean);
  Qusgs = aggregate(as.numeric(yrdat$Qusgs), as.list(yrdat$thisdate), FUN = mean);
  Qtrib = aggregate(as.numeric(yrdat$Qtrib), as.list(yrdat$thisdate), FUN = mean);
  plot(qout, ylim=c(0,pdmax), xlab=paste("Difficult Run", ys, 'to', ye, sep=''));
  #points(yrdat$impoundment_Qout);
  # or at a gage:
  par(pch=22, col="blue") # plotting symbol and color 
  points(Qusgs);
  par(pch=22, col="green") # plotting symbol and color 
  points(Qtrib);
  
  zs <- paste(i, "-04-01", sep='');
  ze <- paste(i, "-04-15", sep='');
  zoomdat <- window(dat, start = as.Date(zs), end = as.Date(ze));
  pdmax = ceiling(max(as.numeric(zoomdat$impoundment_Qin)));
  qout = aggregate(as.numeric(zoomdat$impoundment_Qin), as.list(zoomdat$thisdate), FUN = mean);
  Qusgs = aggregate(as.numeric(zoomdat$Qusgs), as.list(zoomdat$thisdate), FUN = mean);
  Qtrib = aggregate(as.numeric(zoomdat$Qtrib), as.list(zoomdat$thisdate), FUN = mean);
  plot(qout, ylim=c(0,pdmax), xlab=paste("Difficult Run", zs, 'to', ze, sep=''));
  #points(zoomdat$impoundment_Qout);
  # or at a gage:
  par(pch=22, col="blue") # plotting symbol and color 
  points(Qusgs);
  par(pch=22, col="green") # plotting symbol and color 
  points(Qtrib);
}

#stash <- cbind(as.numeric(Qout));
#stash <- cbind(stash, as.numeric(dat$impoundment_Qout))
# or at a gage:
#stash <- cbind(stash, as.numeric(Qusgs))
#fdc(stash);

#fdc(oneyr$Qintake, main="Flow Duration", log='', xlab="Flow Exceedence",
#    ylab="Q cfs", verbose=FALSE);
