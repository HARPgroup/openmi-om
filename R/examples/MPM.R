#Load in a stage storage table and input orifice height, diameter, and normal stage
SS<-read.csv("C:/usr/local/home/git/openmi-om/R/examples/SS.csv")
diameter<-7.9
height<-2
NS<-4.6635

#Load in inflow data (as well as other model data)
fxn_locations = 'C:/usr/local/home/git/hydro-tools/VAHydro-1.0'
source(paste(fxn_locations,"fn_vahydro-1.0.R", sep = "/"))
#source(paste(fxn_locations,"fn_iha.R", sep = "/"))
runid<-7998
elid<-339991
dat<-fn_get_runfile(elid, runid)
S<-dat$impoundment_Storage[1]#Input base storage

#Function to calculate flow from weir stage of our orifice
weir<-function(head,diameter=d){
  flow<-3.1*diameter*head^1.5
  return(flow)
}
#Function to calculate flow from pipe stage of our orifice
pipe<-function(head,diameter=d,height=h){
  flow<-0.6*height*diameter*sqrt(2*32.2*(head-0.5*height))
  return(flow)
}
#Function to calculate outflow based on stage and normal pool elevation
discharge<-function(stage){
  head<-stage-NS
  if(head<0){
    flow<-0
  } else if (head>0&head<height){
      flow<-weir(head,diameter)
  } else if (head>0&head>=height){
    flow<-pipe(head,diameter,height)
  } else {
    flow<-0
  }
  return(flow)
  }
#Function to calculate discharge from a given storage
Solver<-function(Storage){
  Stg<-approx(x=SS$Storage,y=SS$Stage,xout=Storage,rule=1)$y
  Qout<-discharge(Stg)
  return(Qout)
  }
Si<-as.numeric(S)#Creates a loop variable Si with base value S
#Create empty columns to store data. initialize with above boundary conditions
dat$MPMStorage<-numeric(length(dat$impoundment_Qin));dat$MPMStorage[1]<-S
dat$MPMQout<-numeric(length(dat$impoundment_Qin))
dat$MPMStage<-numeric(length(dat$impoundment_Qin));dat$MPMStage[1]<-approx(x=SS$Storage,y=SS$Stage,xout=S,rule=1)$y
#loop that looks at each inflow and calculates storage and outflow simealtaneously by creating a function to 
#find S such that dS=Qin-Qout
for (i in 2:length(dat$impoundment_Qin)){
  Qin<-as.numeric(dat$impoundment_Qin[i])
  S1<-as.numeric(Si)+(Qin*3600/43560)#Maximum possible storage
  Qout1<-Solver(S1)#Maximum possible outflow
  if((S1-Si+Qout1*3600/43560) != (Qin*3600/43560)){#If ds!=Qin-Qout, find a simealtaneous solution
    metric<-function(S){
      Qout<-Solver(S)
      return((S-Si+Qout*3600/43560)-(Qin*3600/43560))
    }
    S1<-uniroot(metric,c(0,max(SS$Storage)))$root#Use uniroot finder to solve for Storage
    Qout1<-Solver(S1)#USe storage to solve for Qout
  }
  Si<-S1
  dat$MPMStorage[i]<-S1
  dat$MPMQout[i]<-Qout1
  dat$MPMStage[i]<-approx(x=SS$Storage,y=SS$Stage,xout=S1,rule=1)$y
}
plot(
#  dat$timestamp,
  as.numeric(dat$MPMStage),
  type='o',
  col='blue',
  lwd=2,
  cex.lab=2,
  cex.axis=2,
  ylim=c(0,200),
  xlab='Time',
  ylab='Stage (ft)'
)
lines(
  as.numeric(dat$impoundment_Qin),
  col='red',
  lwd=2,
  type='o'
)
lines(
  as.numeric(dat$MPMQout),
  col='green',
  lwd=2,
  type='o'
)
lines(
  dat$impoundment_lake_elev,
  col='red',
  lwd=2,
  type='o'
)

legend('topleft',c('MPM','VA Hydro'),col=c('blue','red'),lwd=2,pch=1,cex=2,bty='n',y.intersp = 0.5)


# Just show a specific design storm 
destorm <- window(
  dat, 
  start = as.POSIXct("1989-05-06 16:00"), 
  end = as.POSIXct("1989-05-07 0:00")
);

plot(
  #  dat$timestamp,
  as.numeric(destorm$MPMStage),
  type='o',
  col='blue',
  lwd=2,
  cex.lab=2,
  cex.axis=2,
  ylim=c(0,200),
  xlab='Time',
  ylab='Stage (ft)'
)
lines(
  as.numeric(destorm$impoundment_Qin),
  col='red',
  lwd=2,
  type='o'
)
lines(
  as.numeric(destorm$MPMQout),
  col='green',
  lwd=2,
  type='o'
)
