runid = 6015
dat <- om_get_rundata(247415, runid, site = omsite)
dat_smd <- dat[960:980]
dat_smd <- dat
dat_smd$timestamp <- as.integer(index(dat_smd))
beg<- as.POSIXct( format(min(index(dat_smd)), "%Y-%m-%d %H:%M", tz="EST5EDT"))
bend<- as.POSIXct( format(max(index(dat_smd)), "%Y-%m-%d %H:%M", tz="EST5EDT"))
dat_smd <- as.data.frame(dat_smd)
ts = 12*60*60
tseq <- seq(as.integer(beg), as.integer(bend), by=ts)
tbase <-  as.data.frame(tseq)
names(tbase) <- c('timestamp')


# all at the same time, which can take forever
tsmatrix <- fn$sqldf(
  "
  select a.timestamp as t_start, a.timestamp + $ts as t_end, 
    min(b.timestamp) as first_inner, 
    max(b.timestamp) as last_inner,
    max(c.timestamp) as previous_outer,
    min(d.timestamp) as next_outer
  from tbase as a 
  left outer join dat_smd as b 
  on (
    b.timestamp >= a.timestamp
    and b.timestamp < (a.timestamp + $ts)
  )
  left outer join dat_smd as c 
  on (
    c.timestamp < a.timestamp
  )
  left outer join dat_smd as d 
  on (
    d.timestamp > a.timestamp
  )
  group by a.timestamp
  "
)


# one at a time

tsmatrix1 <- fn$sqldf(
  "
  select a.timestamp as t_start, a.timestamp + $ts as t_end, 
    min(b.timestamp) as first_inner, 
    max(b.timestamp) as last_inner
  from tbase as a 
  left outer join dat_smd as b 
  on (
    b.timestamp >= a.timestamp
    and b.timestamp < (a.timestamp + $ts)
  )
  group by a.timestamp
  "
)

tsmatrix2 <- fn$sqldf(
  "
  select a.t_start, a.t_end, 
    a.first_inner, 
    a.last_inner,
    max(c.timestamp) as previous_outer
  from tsmatrix1 as a 
  left outer join dat_smd as c 
  on (
    c.timestamp < a.t_start
  )
  group by a.t_start
  "
)

tsmatrix3 <- fn$sqldf(
  "
  select a.t_start, a.t_end, 
    a.first_inner, 
    a.last_inner,
    a.previous_outer,
    min(d.timestamp) as next_outer
  from tsmatrix2 as a 
  left outer join dat_smd as d 
  on (
    d.timestamp > a.t_start
  )
  group by a.t_start
  "
)
